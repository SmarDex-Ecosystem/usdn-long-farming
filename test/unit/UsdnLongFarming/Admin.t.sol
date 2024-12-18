// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { DEPLOYER, USER_1 } from "../../utils/Constants.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature The admin functions of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingAdmin is UsdnLongFarmingBaseFixture {
    function setUp() public {
        _setUp();
    }

    /**
     * @custom:scenario Call all admin functions from not admin wallet
     * @custom:given The initial USDN long farming state
     * @custom:when Non-admin wallet triggers admin contract function
     * @custom:then Each function should revert with the same custom error
     */
    function test_RevertWhen_nonAdminWalletCallAdminFunctions() public {
        vm.prank(USER_1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER_1));
        farming.setNotifierRewardsBps(0);
    }

    /**
     * @custom:scenario Call {IUsdnLongFarming.setNotifierRewardsBps} from admin
     * @custom:given The initial USDN long farming state
     * @custom:when Admin wallet triggers admin contract function
     * @custom:then Revert because greater than max
     */
    function test_RevertWhen_setNotifierRewardsBpsToHight() public {
        uint16 max = uint16(farming.BPS_DIVISOR());
        vm.expectRevert(UsdnLongFarmingInvalidNotifierRewardsBps.selector);
        vm.prank(DEPLOYER);
        farming.setNotifierRewardsBps(max + 1);
    }

    /**
     * @custom:scenario Call {IUsdnLongFarming.setNotifierRewardsBps} from admin
     * @custom:given The initial USDN long farming state
     * @custom:when Admin wallet triggers admin contract function
     * @custom:then The notifier rewards bps must be updated
     */
    function test_setNotifierRewardsBps() public {
        uint16 bps = 1000;
        vm.prank(DEPLOYER);
        farming.setNotifierRewardsBps(bps);
        assertEq(farming.getNotifierRewardsBps(), bps, "The notifier rewards bps must be updated");
    }
}
