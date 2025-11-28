// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";

contract UtonomaWithdrawRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");

        uint256 INITIAL_SUPPLY = 1_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);
    }

    function testWithdraw_RevertIfCallerIsNotOwner() public {
        // User A tries to withdraw but is not the owner
        vm.prank(userA);
        vm.expectRevert(bytes("Only the owner can withdraw"));
        utonoma.withdraw();
    }

    function testWithdraw_RevertIfNoFeesCollected() public {
        // Owner calls withdraw, but the contract has no collected fees
        // Contract balance in its own token is zero, so it must revert
        vm.expectRevert(bytes("Nothing to withdraw"));
        utonoma.withdraw();
    }
}
