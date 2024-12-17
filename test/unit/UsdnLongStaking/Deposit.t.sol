// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {deposit} of the USDN long staking
 * @custom:background Given a deployed staking contract and USDN protocol
 */
contract TestUsdnLongStakingDeposit is UsdnLongStakingBaseFixture {
    IUsdnProtocolTypes.Position internal position;
    int24 internal constant DEFAULT_TICK = 1234;
    uint256 internal constant DEFAULT_TICK_VERSION = 123;
    uint256 internal constant DEFAULT_INDEX = 12;

    bytes32 internal _defaultPosHash;

    function setUp() public {
        _setUp();

        position = IUsdnProtocolTypes.Position({
            validated: true,
            timestamp: uint40(block.timestamp),
            user: address(this),
            totalExpo: 1,
            amount: 0
        });

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, false);
        _defaultPosHash = staking.getPosIdHash(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
    }

    /**
     * @custom:scenario Tests the deposit with a valid position.
     * @custom:when The function is called.
     * @custom:then The call must not revert.
     */
    function test_deposit() public {
        vm.expectEmit();
        emit UsdnLongStakingDeposit(address(this), _defaultPosHash);
        bool success = staking.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");
        assertTrue(success, "The deposit must be successful");
    }
}
