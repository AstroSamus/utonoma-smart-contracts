// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Time} from "../../contracts/Time.sol";

contract TimeTest is Test {
    
    Time time;

    function testStartTimeMatchesDeploymentBlock() public {
        // Deploy contract
        time = new Time();

        // Timestamp of current block
        uint256 blockTimestamp = block.timestamp;

        // Stored start time in contract
        uint256 start = time.startTimeOfTheNetwork();

        // Should match exactly the timestamp at deployment
        assertEq(start, blockTimestamp, "Start time should equal deployment block timestamp");
    }

    function testStartTimeDoesNotChangeWithTimeAdvance() public {
        time = new Time();

        uint256 initialStart = time.startTimeOfTheNetwork();

        // Fast-forward 1 week
        vm.warp(block.timestamp + 7 days);

        uint256 afterWarp = time.startTimeOfTheNetwork();

        // Must be identical
        assertEq(afterWarp, initialStart, "Start time should remain immutable");
    }
}
