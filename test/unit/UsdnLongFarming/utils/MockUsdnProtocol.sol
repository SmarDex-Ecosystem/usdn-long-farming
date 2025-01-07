// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IOwnershipCallback } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IOwnershipCallback.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

contract MockUsdnProtocol {
    IUsdnProtocolTypes.Position internal _position;
    bool internal _liquidated;
    uint256 internal _tickVersion;

    function getLongPosition(IUsdnProtocolTypes.PositionId calldata)
        external
        view
        returns (IUsdnProtocolTypes.Position memory position_, uint256 liquidationPenalty_)
    {
        return (_position, 0);
    }

    function setPosition(IUsdnProtocolTypes.Position calldata position, uint256 tickVersion, bool liquidated)
        external
    {
        _position = position;
        _liquidated = liquidated;
        _tickVersion = tickVersion;
    }

    function transferPositionOwnership(IUsdnProtocolTypes.PositionId calldata posId, address newOwner, bytes calldata)
        external
    {
        address oldOwner = _position.user;
        _position.user = newOwner;

        IOwnershipCallback(newOwner).ownershipCallback(oldOwner, posId);
    }

    function getTickVersion(int24 /*tick*/ ) external view returns (uint256 tickVersion_) {
        if (_liquidated) {
            return _tickVersion + 1;
        } else {
            return _tickVersion;
        }
    }
}
