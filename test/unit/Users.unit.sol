// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Users} from "../../contracts/Users.sol";
import {console} from "forge-std/console.sol";


abstract contract Comparators {
    /// @dev Compares two arrays, returns true if they are equal
    function arrayComparator(uint256[] memory array1, uint256[] memory array2) public pure returns (bool) {
        if (array1.length != array2.length) return false;

        for (uint256 i = 0; i < array1.length; i++) {
            if (array1[i] != array2[i]) return false;
        }

        return true;
    }
}

/** 
* @dev A harness contract to expose internal methods of Users for testing. The vm.prank only
* works with external calls, but _logUserInteraction and other methods from this contracts are 
* internal, so we need to expose them here. 
* To call these methods you need to call them by using this.methodName(...) so it is an external call.
*/
contract UsersHarness is Users {
    function logInteraction(uint256 currentTime, uint256 startTimeOfNetwork) public {
        _logUserInteraction(currentTime, startTimeOfNetwork);
    }
    function addStrike(address contentCreator) public {
        _addStrike(contentCreator);
    }
}


contract UsersTest is Test, Comparators {
    UsersHarness users;
    
    // startTime = Sun Jan 15 2023 06:00:00 GMT+0000
    uint256 startTime = 1673762400;
    // currentTime = Mon Jan 16 2023 06:00:00 GMT+0000 (One day after start time)
    uint256 currentTime = 1673848800;

    uint256[] MAUReport;

    // Helpers for "accounts"
    address account0 = address(0xA0);
    address account1 = address(0xA1);
    address account2 = address(0xA2);
    address account3 = address(0xA3);
    address account5 = address(0xA5);
    address account6 = address(0xA6);

    function setUp() public {
        users = new UsersHarness();
    }

    // -------------------------------------------------------------------------
    // currentPeriodMAU
    // -------------------------------------------------------------------------

    function testCurrentPeriodMAUForNoUsers() public view {
        AssertEqualUint(
            users.currentPeriodMAU(),
            0,
            "When using the currentPeriodMAU method at the initialization of the smart contract, the result should be 0 users"
        );
    }

    /**
    * @dev Check the calendar of periods for the MAU calculation.
    *   First period: start = 1673762400, end = 1676354399;
    *   Second period: start = 1676354400, end = 1678946399;
    *   Third period: start = 1678946400, end = 1681538399;
    *   Fourth period: start = 1681538400, end = 1684130399;
    *   Fifth period: start = 1684130400, end = 1686722399;
    *   Sixth period: start = 1686722400, end = 1689314399;
    *   Seventh period: start = 1689314400, end = 1691906399;
    *   Eigth period: start = 1691906400, end = 1694498399;
    *   Nineth period: start = 1694498400, end = 1697090399.
    */
    function testLogUserInteraction_MAUFullScenario() public {
        // ─────────────────────────────────────────────────────────────
        // 1) Two interactions (first month) from two different accounts
        // ─────────────────────────────────────────────────────────────

        // #sender: account-5
        vm.prank(account5);
        users.logInteraction(currentTime, startTime);

        // #sender: account-6
        vm.prank(account6);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [2]
        AssertEqualUint(
            users.currentPeriodMAU(),
            2,
            "When using the currentPeriodMAU method in the first month, the result should be number of users of the current month (that is 2)"
        );

        // #sender: account-1
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3] (two from the previous test and one from this)
        MAUReport.push(3);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method from an account that interacts for the fisrt time with the contract, the MAU report should reflect one user"
        );

        // Mon Jan 21 2023 06:00:00 GMT+0000 (five days after the first interaction)
        currentTime = 1674280800;
        vm.prank(account1); //the same user interacts again in the same period
        users.logInteraction(currentTime, startTime);

        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the second time with the same account in the current period, the MAU report should only reflect one user"
        );
        AssertEqualUint(
            users.getLatestInteractionTime(account1),
            currentTime,
            "When using the logUserInteraction method for the second time with the same account in the current period, the latest interaction time of the user should correspond to the time of the latest call to the method"
        );

        // Tue Feb 14 2023 06:00:00 GMT+0000 (at the start of the second period)
        currentTime = 1676354400;
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1]
        MAUReport.push(1);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time since the start of the second period from an account that interacted in the pervious period, MAU report should count one user in the starting period"
        );

        // Sat Apr 15 2023 06:00:00 GMT+0000 (in the fourth period after skipping the third one)
        currentTime = 1681538400;
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1,0,1]
        MAUReport.push(0);
        MAUReport.push(1);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time after one period with no users, the MAU report of the period with no users should be in zero and the current one should be in one"
        );

        // Sun Aug 13 2023 06:00:00 GMT+0000 (Begining of the eigth period after three monts with no users)
        currentTime = 1691906400;
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1,0,1,0,0,0,1]
        MAUReport.push(0);
        MAUReport.push(0);
        MAUReport.push(0);
        MAUReport.push(1);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time after three periods with no users, the MAU report of the three periods with no users should be in zero and the current one should be in one"
        );

        // Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)
        currentTime = 1694498400;
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);
        vm.prank(account1);
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1,0,1,0,0,0,1,1]
        MAUReport.push(1);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method twice at the same exact time with the same account, the MAU report should only reflect one user and not two"
        );

        currentTime = 1694498400; // same time
        vm.prank(account2); //second user in the same period
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1,0,1,0,0,0,1,2]
        MAUReport[MAUReport.length - 1] += 1;
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method twice in the same period from two different accounts, the MAU report should reflect two users for the current period"
        );

        vm.prank(account2);
        users.logInteraction(currentTime, startTime);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method three times in the same period from two different accounts, the MAU report should reflect only two users for the current period and not three"
        );

        currentTime = 1694498400;
        vm.prank(account3); //third user in the same period
        users.logInteraction(currentTime, startTime);

        // MAUReport should be [3,1,0,1,0,0,0,1,3]
        MAUReport[MAUReport.length - 1] += 1;
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method three times in the same period from three different accounts, the MAU report should reflect three users for the current period"
        );

        vm.prank(account3);
        users.logInteraction(currentTime, startTime);
        AssertOk(
            arrayComparator(users.historicMAUData(), MAUReport),
            "When using the logUserInteraction method multiple times in the same period from three different accounts, the MAU report should reflect only three users for the current period"
        );

        // Current time is: Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)
        // Current period has 3 users if we get the MAU we should get the users of the previous
        // period (1)
        AssertEqualUint(
            users.currentPeriodMAU(),
            1,
            "When using the currentPeriodMAU method at the begining of the nineth period, the result should be the number of users of the eight period, that is 1"
        );
    }

    // -------------------------------------------------------------------------
    // createUser / updateUserMetadataHash / _addStrike
    // -------------------------------------------------------------------------

    function testCreateUserSuccess() public {
        // #sender: account-0
        vm.prank(account0);
        bytes15 proposedUserName = bytes15(0x757365725f6e616d655f3100000000); // user_name_1
        bytes32 mockMetadata = bytes32(
            0x7465737400000000000000000000000000000000000000000000000000000000
        );
        users.createUser(proposedUserName, mockMetadata);

        address nameOwner = users.getUserNameOwner(proposedUserName);
        Users.UserProfile memory userProfile = users.getUserProfile(account0);

        AssertEqualBytes15(
            userProfile.userName,
            proposedUserName,
            "After using the createUser method, the username in the profile of the user should be the one that was passed as an argument to the method"
        );

        AssertEqualBytes32(
            userProfile.userMetadataHash,
            mockMetadata,
            "After using the createUser method, the userMetadataHash in the profile of the user should be the one that was passed as an argument to the method"
        );

        AssertEqualAddress(
            nameOwner,
            account0,
            "After using the createUser method, the message sender should be the owner of the username"
        );
    }

    function testUpdateUserMetadataHashSuccess() public {
        // First create the user
        vm.prank(account0);
        bytes15 proposedUserName = bytes15(0x757365725f6e616d655f3100000000); // user_name_1
        bytes32 mockMetadata = bytes32(
            0x7465737400000000000000000000000000000000000000000000000000000000
        );
        users.createUser(proposedUserName, mockMetadata);

        // #sender: account-0
        vm.prank(account0);
        bytes32 newMetadata = bytes32(
            0x0000000000000000000000000000000000000000000000000000000000456123
        );
        users.updateUserMetadataHash(newMetadata);

        Users.UserProfile memory userProfile = users.getUserProfile(account0);

        AssertEqualBytes32(
            newMetadata,
            userProfile.userMetadataHash,
            "After using the updateUserMetadataHash method, the userMetadataHash in the user profile that calls the method should be overwritten with the new information"
        );
    }

    function testAddStrikeSuccess() public {
        // Create user first (same as in createUserSuccess)
        vm.prank(account0);
        bytes15 proposedUserName = bytes15(0x757365725f6e616d655f3100000000); // user_name_1
        bytes32 mockMetadata = bytes32(
            0x7465737400000000000000000000000000000000000000000000000000000000
        );
        users.createUser(proposedUserName, mockMetadata);

        uint256 strikesNumberBefore = users.getUserProfile(account0).strikes;

        users.addStrike(account0);

        uint256 strikesNumberAfter = users.getUserProfile(account0).strikes;

        AssertEqualUint(
            strikesNumberAfter,
            strikesNumberBefore + 1,
            "After using the addStrike method, the number of strikes in the user profile should be increased by one"
        );
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function AssertEqualUint(uint256 a, uint256 b, string memory message) internal pure {
        assertEq(a, b, message);
    }

    function AssertEqualAddress(address a, address b, string memory message) internal pure {
        assertEq(a, b, message);
    }

    function AssertEqualBytes32(bytes32 a, bytes32 b, string memory message) internal  pure {
        assertEq(a, b, message);
    }

    function AssertEqualBytes15(bytes15 a, bytes15 b, string memory message) internal pure {
        require(a == b, message);
    }

    function AssertOk(bool condition, string memory message) internal pure {
        require(condition, message);
    }
}