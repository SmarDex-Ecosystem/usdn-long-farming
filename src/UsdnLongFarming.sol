// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin-contracts-5/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin-contracts-5/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin-contracts-5/utils/ReentrancyGuard.sol";
import { ERC165 } from "@openzeppelin-contracts-5/utils/introspection/ERC165.sol";
import { IERC165, IOwnershipCallback } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IOwnershipCallback.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady-0.0.281/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "solady-0.0.281/utils/SafeTransferLib.sol";

import { IFarmingRange } from "./interfaces/IFarmingRange.sol";
import { IUsdnLongFarming } from "./interfaces/IUsdnLongFarming.sol";

/**
 * @title USDN Long Positions farming
 * @notice A contract for farming USDN long positions to earn rewards.
 */
contract UsdnLongFarming is ERC165, ReentrancyGuard, IUsdnLongFarming, Ownable2Step {
    using SafeTransferLib for address;

    /**
     * @dev Scaling factor for {_accRewardPerShare}.
     * In the worst case of having 1 wei of reward tokens per block for a duration of 1 block, and with a total number
     * of shares equivalent to 500 million wstETH, the accumulator value increment would still be 2e11 which is
     * precise enough.
     */
    uint256 public constant SCALING_FACTOR = 1e38;

    /// @notice Denominator for the rewards multiplier, will give us a 0.01% basis point.
    uint256 public constant BPS_DIVISOR = 10_000;

    /// @notice Address where to send the rewards to burn.
    address public constant DEAD_ADDRESS = address(0xdead);

    /// @notice The address of the USDN protocol contract.
    IUsdnProtocol public immutable USDN_PROTOCOL;

    /// @notice The address of the SmarDex rewards provider contract, which is the source of the reward tokens.
    IFarmingRange public immutable REWARDS_PROVIDER;

    /// @notice The ID of the campaign in the SmarDex rewards provider contract which provides reward tokens to this
    /// contract.
    uint256 public immutable CAMPAIGN_ID;

    /// @notice The address of the reward token.
    IERC20 public immutable REWARD_TOKEN;

    /// @dev The position information for each locked position, identified by the hash of its `PositionId`.
    mapping(bytes32 => PositionInfo) internal _positions;

    /// @dev The total number of locked positions.
    uint256 internal _positionsCount;

    /// @dev The sum of all locked positions' initial trading exposure.
    uint256 internal _totalShares;

    /**
     * @dev Accumulated reward tokens per share multiplied by {SCALING_FACTOR}.
     * The factor is necessary to represent rewards per shares with enough precision for very small reward quantities
     * and large total number of shares.
     * In the worst case of having a very large number of reward tokens per block (1000e18) and a very small total
     * number of shares (1 wei), this number would not overflow for 1.158e18 blocks which is ~440 billion years.
     */
    uint256 internal _accRewardPerShare;

    /// @dev Block number when the last rewards were calculated.
    uint256 internal _lastRewardBlock;

    /// @dev Ratio of the rewards to be distributed to the notifier in basis points: default is 30%.
    uint16 internal _notifierRewardsBps = 3000;

    /**
     * @param usdnProtocol The address of the USDN protocol contract.
     * @param rewardsProvider The address of the SmarDex rewards provider contract.
     * @param campaignId The campaign ID in the SmarDex rewards provider contract which provides reward tokens to this
     * contract.
     */
    constructor(IUsdnProtocol usdnProtocol, IFarmingRange rewardsProvider, uint256 campaignId) Ownable(msg.sender) {
        USDN_PROTOCOL = usdnProtocol;
        REWARDS_PROVIDER = rewardsProvider;
        CAMPAIGN_ID = campaignId;
        IFarmingRange.CampaignInfo memory info = rewardsProvider.campaignInfo(campaignId);
        REWARD_TOKEN = IERC20(address(info.rewardToken));
        IERC20 farmingToken = IERC20(address(info.stakingToken));
        // this contract is the sole depositor of the farming token in the SmarDex rewards provider contract,
        // and will receive all of the rewards
        address(farmingToken).safeTransferFrom(msg.sender, address(this), 1);
        farmingToken.approve(address(rewardsProvider), 1);
        rewardsProvider.deposit(campaignId, 1);
    }

    /// @inheritdoc IUsdnLongFarming
    function setNotifierRewardsBps(uint16 notifierRewardsBps) external onlyOwner {
        if (notifierRewardsBps > BPS_DIVISOR) {
            revert UsdnLongFarmingInvalidNotifierRewardsBps();
        }
        _notifierRewardsBps = notifierRewardsBps;
        emit NotifierRewardsBpsUpdated(notifierRewardsBps);
    }

    /// @inheritdoc IUsdnLongFarming
    function getPositionInfo(bytes32 posHash) external view returns (PositionInfo memory info_) {
        return _positions[posHash];
    }

    /// @inheritdoc IUsdnLongFarming
    function getPositionsCount() external view returns (uint256 count_) {
        return _positionsCount;
    }

    /// @inheritdoc IUsdnLongFarming
    function getTotalShares() external view returns (uint256 shares_) {
        return _totalShares;
    }

    /// @inheritdoc IUsdnLongFarming
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_) {
        return _accRewardPerShare;
    }

    /// @inheritdoc IUsdnLongFarming
    function getLastRewardBlock() external view returns (uint256 block_) {
        return _lastRewardBlock;
    }

    /// @inheritdoc IUsdnLongFarming
    function pendingRewards(int24 tick, uint256 tickVersion, uint256 index) external view returns (uint256 rewards_) {
        if (_totalShares == 0) {
            return 0;
        }

        uint256 periodRewards = REWARDS_PROVIDER.pendingReward(CAMPAIGN_ID, address(this));
        uint256 newAccRewardPerShare = _calcAccRewardPerShare(periodRewards);
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);
        (rewards_,) = _calcRewards(_positions[positionIdHash], newAccRewardPerShare);
    }

    /// @inheritdoc IUsdnLongFarming
    function hashPosId(int24 tick, uint256 tickVersion, uint256 index) external pure returns (bytes32 hash_) {
        return _hashPositionId(tick, tickVersion, index);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOwnershipCallback).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IUsdnLongFarming
    function getNotifierRewardsBps() external view returns (uint16 notifierRewardsBps_) {
        return _notifierRewardsBps;
    }

    /// @inheritdoc IOwnershipCallback
    function ownershipCallback(address oldOwner, IUsdnProtocolTypes.PositionId calldata posId) external nonReentrant {
        if (msg.sender != address(USDN_PROTOCOL)) {
            revert UsdnLongFarmingInvalidCaller();
        }

        (IUsdnProtocolTypes.Position memory pos,) =
            USDN_PROTOCOL.getLongPosition(IUsdnProtocolTypes.PositionId(posId.tick, posId.tickVersion, posId.index));

        if (!pos.validated) {
            revert UsdnLongFarmingPendingPosition();
        }
        _registerDeposit(oldOwner, pos, posId.tick, posId.tickVersion, posId.index);
    }

    /// @inheritdoc IUsdnLongFarming
    function harvest(int24 tick, uint256 tickVersion, uint256 index)
        external
        nonReentrant
        returns (bool isLiquidated_, uint256 rewards_)
    {
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);

        (bool isLiquidated, uint256 rewards, uint256 newRewardDebt, address owner) = _harvest(positionIdHash);

        if (isLiquidated) {
            _slash(positionIdHash, rewards, msg.sender, tick, tickVersion, index);
            return (true, 0);
        } else if (rewards > 0) {
            _positions[positionIdHash].rewardDebt = newRewardDebt;
            _sendRewards(owner, rewards, tick, tickVersion, index);
            return (false, rewards);
        }
    }

    /// @inheritdoc IUsdnLongFarming
    function withdraw(int24 tick, uint256 tickVersion, uint256 index)
        external
        nonReentrant
        returns (bool isLiquidated_, uint256 rewards_)
    {
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);

        address owner;
        (isLiquidated_, rewards_,, owner) = _harvest(positionIdHash);

        if (isLiquidated_) {
            _slash(positionIdHash, rewards_, msg.sender, tick, tickVersion, index);
            return (true, 0);
        }
        if (msg.sender != owner) {
            revert UsdnLongFarmingInvalidCaller();
        }
        if (rewards_ > 0) {
            _sendRewards(owner, rewards_, tick, tickVersion, index);
        }

        _deletePosition(positionIdHash);

        emit Withdraw(owner, tick, tickVersion, index);
        USDN_PROTOCOL.transferPositionOwnership(IUsdnProtocolTypes.PositionId(tick, tickVersion, index), owner, "");
    }

    /**
     * @notice Hashes a USDN long position's ID to use as key in the {_positions} mapping.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The hash of the position ID.
     */
    function _hashPositionId(int24 tick, uint256 tickVersion, uint256 index) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(tick, tickVersion, index));
    }

    /**
     * @notice Records the information for a new position deposit.
     * @dev Uses the initial position trading expo as shares.
     * @param owner The prior USDN protocol position owner.
     * @param position The USDN protocol position to deposit.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function _registerDeposit(
        address owner,
        IUsdnProtocolTypes.Position memory position,
        int24 tick,
        uint256 tickVersion,
        uint256 index
    ) internal {
        _updateRewards();
        uint128 initialTradingExpo = position.totalExpo - position.amount;
        PositionInfo memory posInfo = PositionInfo({
            owner: owner,
            tick: tick,
            tickVersion: tickVersion,
            index: index,
            rewardDebt: FixedPointMathLib.fullMulDiv(initialTradingExpo, _accRewardPerShare, SCALING_FACTOR),
            shares: initialTradingExpo
        });

        _totalShares += posInfo.shares;
        _positionsCount++;
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);
        _positions[positionIdHash] = posInfo;

        emit Deposit(posInfo.owner, tick, tickVersion, index);
    }

    /**
     * @notice Updates {_lastRewardBlock}, harvests pending rewards from the SmarDex rewards provider contract, and
     * updates {_accRewardPerShare}.
     * @dev If no deposited position exists, {_lastRewardBlock} will be updated, but rewards will not be harvested.
     */
    function _updateRewards() internal {
        if (_lastRewardBlock == block.number) {
            return;
        }

        _lastRewardBlock = block.number;

        if (_totalShares == 0) {
            return;
        }

        uint256 rewardsBalanceBefore = REWARD_TOKEN.balanceOf(address(this));

        // farming harvest
        uint256[] memory campaignsIds = new uint256[](1);
        campaignsIds[0] = CAMPAIGN_ID;
        // slither-disable-next-line reentrancy-no-eth
        REWARDS_PROVIDER.harvest(campaignsIds);

        uint256 periodRewards = REWARD_TOKEN.balanceOf(address(this)) - rewardsBalanceBefore;

        if (periodRewards > 0) {
            _accRewardPerShare = _calcAccRewardPerShare(periodRewards);
        }
    }

    /**
     * @notice Verifies if the position has been liquidated in the USDN protocol and calculates the rewards to be
     * distributed.
     * @param positionIdHash The hash of the position ID.
     * @return isLiquidated_ Whether the position has been liquidated.
     * @return rewards_ The rewards amount to be distributed.
     * @return newRewardDebt_ The new reward debt for the position.
     * @return owner_ The owner of the position.
     */
    function _harvest(bytes32 positionIdHash)
        internal
        returns (bool isLiquidated_, uint256 rewards_, uint256 newRewardDebt_, address owner_)
    {
        _updateRewards();
        PositionInfo memory posInfo = _positions[positionIdHash];
        if (posInfo.owner == address(0)) {
            revert UsdnLongFarmingInvalidPosition();
        }

        owner_ = posInfo.owner;
        (rewards_, newRewardDebt_) = _calcRewards(posInfo, _accRewardPerShare);
        isLiquidated_ = _isLiquidated(posInfo.tick, posInfo.tickVersion);
    }

    /**
     * @notice Calculates the rewards to be distributed to a position.
     * @param posInfo The position information.
     * @param accRewardPerShare The accumulator rewards per share.
     * @return rewards_ The rewards amount to be distributed.
     * @return newRewardDebt_ The new reward debt for the position.
     */
    function _calcRewards(PositionInfo memory posInfo, uint256 accRewardPerShare)
        internal
        pure
        returns (uint256 rewards_, uint256 newRewardDebt_)
    {
        newRewardDebt_ = FixedPointMathLib.fullMulDiv(posInfo.shares, accRewardPerShare, SCALING_FACTOR);
        rewards_ = newRewardDebt_ - posInfo.rewardDebt;
    }

    /**
     * @notice Sends the rewards to the `to` address and emits a {Harvest} event.
     * @param to The address to send the rewards to.
     * @param amount The amount of rewards to send.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function _sendRewards(address to, uint256 amount, int24 tick, uint256 tickVersion, uint256 index) internal {
        address(REWARD_TOKEN).safeTransfer(to, amount);
        emit Harvest(to, amount, tick, tickVersion, index);
    }

    /**
     * @notice Checks if a position has been liquidated in the USDN protocol.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @return isLiquidated_ Whether the position has been liquidated.
     */
    function _isLiquidated(int24 tick, uint256 tickVersion) internal view returns (bool isLiquidated_) {
        uint256 protocolTickVersion = USDN_PROTOCOL.getTickVersion(tick);
        return protocolTickVersion != tickVersion;
    }

    /**
     * @notice Slashes a position and splits the rewards between the notifier and the dead address.
     * @param positionIdHash The hash of the position ID.
     * @param rewards The rewards amount to be distributed.
     * @param notifier The address which has notified the farming platform about the liquidation in the USDN protocol.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     */
    function _slash(
        bytes32 positionIdHash,
        uint256 rewards,
        address notifier,
        int24 tick,
        uint256 tickVersion,
        uint256 index
    ) internal {
        _deletePosition(positionIdHash);

        if (rewards == 0) {
            emit Slash(notifier, 0, 0, tick, tickVersion, index);
        } else {
            uint256 notifierRewards = rewards * _notifierRewardsBps / BPS_DIVISOR;
            uint256 burnedTokens = rewards - notifierRewards;
            address(REWARD_TOKEN).safeTransfer(DEAD_ADDRESS, burnedTokens);
            address(REWARD_TOKEN).safeTransfer(notifier, notifierRewards);
            emit Slash(notifier, notifierRewards, burnedTokens, tick, tickVersion, index);
        }
    }

    /**
     * @notice Calculates and returns the updated accumulated reward per share.
     * @param periodRewards The period amount of rewards to consider when calculating the updated reward per share.
     * @return accRewardPerShare_ The updated accumulated reward per share.
     */
    function _calcAccRewardPerShare(uint256 periodRewards) internal view returns (uint256 accRewardPerShare_) {
        return _accRewardPerShare + FixedPointMathLib.fullMulDiv(periodRewards, SCALING_FACTOR, _totalShares);
    }

    /**
     * @notice Deletes a position from the internal state, updates the total shares and positions count.
     * @param positionIdHash The hash of the position ID.
     */
    function _deletePosition(bytes32 positionIdHash) internal {
        _totalShares -= _positions[positionIdHash].shares;
        _positionsCount--;
        delete _positions[positionIdHash];
    }
}
