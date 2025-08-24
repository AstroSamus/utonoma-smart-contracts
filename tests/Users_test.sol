// SPDX-License-Identifier: MIT
        
pragma solidity 0.8.22;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/Users.sol";
import {Comparators} from "tests/test_utils/Comparators.sol";

contract Users_test is Users, Comparators {

    uint256 startTime = 1673762400; //Sun Jan 15 2023 06:00:00 GMT+0000
    uint256 currentTime = 1673848800; //Mon Jan 16 2023 06:00:00 GMT+0000 (One day after start time)
    uint256[] MAUReport; 

    function currentPeriodMAUForNoUsers() public {
        Assert.equal(
            currentPeriodMAU(),
            0,
            "When using the currentPeriodMAU method at the initialization of the smart contract, the result should be 0 users"
        );
    }

    /// @dev Generate one interaction for the next test
    /// #sender: account-5
    function generateOneInteracionForTheNextTest() public {
        _logUserInteraction(currentTime, startTime);
    }
    /// #sender: account-6
    function currentPeriodMAUForTheFirstMonth() public {
        _logUserInteraction(currentTime, startTime);
        Assert.equal(
            currentPeriodMAU(),
            2,
            "When using the currentPeriodMAU method in the first month, the result should be number of users of the current month (that is 2)"
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
    /// #sender: account-1
    function logUserInteractionForASingleUser() public {
        
        _logUserInteraction(currentTime, startTime);

        MAUReport.push(3);//MAUReport should be [3] (two from the previous test and one from this)
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method from an account that interacts for the fisrt time with the contract, the MAU report should reflect one user"
        );
        
        currentTime = 1674280800; //Sat Jan 21 2023 06:00:00 GMT+0000 (five days after the first interaction)
        _logUserInteraction(currentTime, startTime);


        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the second time with the same account in the current period, the MAU report should only reflect one user"
        );
        Assert.equal( 
            getLatestInteractionTime(TestsAccounts.getAccount(1)),
            currentTime,
            "When using the logUserInteraction method for the second time with the same account in the current period, the latest interaction time of the user should correspond to the time of the latest call to the method"
        );


        currentTime = 1676354400; //Tue Feb 14 2023 06:00:00 GMT+0000 (at the start of the second period)
        _logUserInteraction(currentTime, startTime);

        MAUReport.push(1); //MAUReport should be [3,1]
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time since the start of the second period from an account that interacted in the pervious period, MAU report should count one user in the starting period"
        );


        currentTime = 1681538400; //Sat Apr 15 2023 06:00:00 GMT+0000 (in the fourth period after skipping the third one)
        _logUserInteraction(currentTime, startTime);

        MAUReport.push(0);
        MAUReport.push(1); //MAUReport should be [3,1,0,1]
        Assert.ok( 
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time after one period with no users, the MAU report of the period with no users should be in zero and the current one should be in one"
        );


        currentTime = 1691906400; //Sun Aug 13 2023 06:00:00 GMT+0000 (Begining of the eigth period after three monts with no users)  
        _logUserInteraction(currentTime, startTime);

        MAUReport.push(0);
        MAUReport.push(0);
        MAUReport.push(0);
        MAUReport.push(1); //MAUReport should be [3,1,0,1,0,0,0,1]
        Assert.ok( 
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method for the first time after three periods with no users, the MAU report of the three periods with no users should be in zero and the current one should be in one"
        );


        currentTime = 1694498400; //Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)          
        _logUserInteraction(currentTime, startTime);
        _logUserInteraction(currentTime, startTime);

        MAUReport.push(1); //MAUReport should be [3,1,0,1,0,0,0,1,1]
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method twice at the same exact time with the same account, the MAU report should only reflect one user and not two"
        );
    }

    /// #sender: account-2
    function logUserInteractionForTwoUsers() public {
        currentTime = 1694498400; //Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)
        _logUserInteraction(currentTime, startTime);

        MAUReport[MAUReport.length - 1]++; //MAUReport should be [3,1,0,1,0,0,0,1,2]
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method twice in the same period from two different accounts, the MAU report should reflect two users for the current period"
        );
        

        _logUserInteraction(currentTime, startTime);
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method three times in the same period from two different accounts, the MAU report should reflect only two users for the current period and not three"
        );
    }

    /// #sender: account-3
    function logUserInteractionForThreeUsers() public {
        currentTime = 1694498400; //Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)
        _logUserInteraction(currentTime, startTime);

        MAUReport[MAUReport.length - 1]++; //MAUReport should be [3,1,0,1,0,0,0,1,3]
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method three times in the same period from three different accounts, the MAU report should reflect three users for the current period"
        );
        

        _logUserInteraction(currentTime, startTime);
        Assert.ok(
            arrayComparator(historicMAUData(), MAUReport),
            "When using the logUserInteraction method multiple times in the same period from three different accounts, the MAU report should reflect only three users for the current period"
        );
    }

    function currentPeriodMAUForMoreThanAMonthOfExistanceOfTheApp() public {
        //Current time is: Tue Sep 12 2023 06:00:00 GMT+0000 (Begining of the nineth period)
        //Current period has 3 users if we get the MAU we should get the users of the previous
        //period (1)
        Assert.equal(
            currentPeriodMAU(),
            1,
            "When using the currentPeriodMAU method at the begining of the nineth period, the result should be the number of users of the eight period, that is 1"
        );
    }    

    /// #sender: account-0
    function createUserSuccess() public {
        bytes15 proposedUserName = bytes15(0x757365725f6e616d655f3100000000); //user_name_1
        bytes32 mockMetadata = bytes32(0x7465737400000000000000000000000000000000000000000000000000000000);
        createUser(proposedUserName, mockMetadata);

        address nameOwner = getUserNameOwner(proposedUserName);
        UserProfile memory userProfile = getUserProfile(TestsAccounts.getAccount(0));

        Assert.equal(
            userProfile.userName,
            proposedUserName,
            "After using the createUser method, the username in the profile of the user should be the one that was passed as an argument to the method"
        );

        Assert.equal(
            userProfile.userMetadataHash,
            mockMetadata,
            "After using the createUser method, the userMetadataHash in the profile of the user should be the one that was passed as an argument to the method"
        );

        Assert.equal(
            nameOwner,
            TestsAccounts.getAccount(0),
            "After using the createUser method, the message sender should be the owner of the username"
        );

    }

    /// #sender: account-0
    function updateUserMetadataHashSuccess() public {
        bytes32 newMetadata = bytes32(0x0000000000000000000000000000000000000000000000000000000000456123);
        updateUserMetadataHash(newMetadata);

        UserProfile memory userProfile = getUserProfile(TestsAccounts.getAccount(0));

        Assert.equal(
            newMetadata,
            userProfile.userMetadataHash,
            "After using the updateUserMetadataHash method, the userMetadataHash in the user profile that calls the method should be overwritten with the new information"
        );
    }

    /// #sender: account-0
    function addStrikeSuccess() public {
        uint256 strikesNumberBefore = getUserProfile(TestsAccounts.getAccount(0)).strikes;
        _addStrike(TestsAccounts.getAccount(0));
        uint256 strikesNumberAfter = getUserProfile(TestsAccounts.getAccount(0)).strikes;

        Assert.equal(
            strikesNumberAfter,
            strikesNumberBefore + 1,
            "After using the addStrike method, the number of strikes in the user profile should be increased by one"
        );
    }
    
}