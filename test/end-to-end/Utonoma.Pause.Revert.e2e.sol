// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";

contract UtonomaPauseRevertTest is Test {
    Utonoma internal utonoma;

    // In this setup, the test contract (address(this)) is the deployer,
    // so it becomes the owner inside Utonoma.
    address internal owner = address(this);
    address internal userA = address(0xA1);

    uint256 internal constant INITIAL_SUPPLY = 5_000_000 ether;

    function setUp() public {
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);
    }

    function testPause_RevertWhenCallerIsNotOwner() public {
        // User A (not the owner) tries to pause the contract
        vm.prank(userA);
        vm.expectRevert("Only the owner can pause");
        utonoma.pause();
    }
}
