// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

contract MockUsdnProtocol {
    IUsdnProtocolTypes.Position internal _position;

    function getCurrentLongPosition(int24, uint256)
        external
        view
        returns (IUsdnProtocolTypes.Position memory position_)
    {
        return _position;
    }

    function setPosition(IUsdnProtocolTypes.Position calldata position) external {
        _position = position;
    }

    function transferPositionOwnership(IUsdnProtocolTypes.PositionId calldata, address newOwner, bytes calldata)
        external
    {
        _position.user = newOwner;
    }
}
