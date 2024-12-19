// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IOwnershipCallback } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IOwnershipCallback.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

contract MockUsdnProtocol {
    IUsdnProtocolTypes.Position internal _position;

    function getLongPosition(IUsdnProtocolTypes.PositionId calldata)
        external
        view
        returns (IUsdnProtocolTypes.Position memory position_, uint256 liquidationPenalty_)
    {
        return (_position, 0);
    }

    function setPosition(IUsdnProtocolTypes.Position calldata position) external {
        _position = position;
    }

    function transferPositionOwnership(IUsdnProtocolTypes.PositionId calldata posId, address newOwner, bytes calldata)
        external
    {
        address oldOwner = _position.user;
        _position.user = newOwner;

        IOwnershipCallback(newOwner).ownershipCallback(oldOwner, posId);
    }
}
