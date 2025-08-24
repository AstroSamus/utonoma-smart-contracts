// SPDX-License-Identifier: MIT
        
pragma solidity 0.8.22;

import "remix_tests.sol";
import "../contracts/Utils.sol";

contract Utils_test {

    Utils utils;

    function beforeAll() public {
        utils = new Utils();
    }

    function shouldContentBeEliminated() public {

        //True cases
        Assert.equal(
            utils.shouldContentBeEliminated(24, 76),
            true, 
            "shouldContentBeEliminated method, when receiving 24 likes and 76 dislikes, should return true (0.6763 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(1, 8),
            true, 
            "shouldContentBeEliminated method, when receiving 1 likes and 8 dislikes, should return true (0.6836 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(0, 6),
            true, 
            "shouldContentBeEliminated method, when receiving 0 likes and 6 dislikes, should return true (in case there are no likes, ouptut will default true as long as the minimum quorum is reached)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(13, 47),
            true, 
            "shouldContentBeEliminated method, when receiving 13 likes and 47 dislikes, should return true (0.6791 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(43310, 98100),
            true, 
            "shouldContentBeEliminated method, when receiving 13 likes and 47 dislikes, should return true (0.6791 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(43310, 98100),
            true, 
            "shouldContentBeEliminated method, when receiving 13 likes and 47 dislikes, should return true (0.6791 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(4950000000, 10050000000),
            true, 
            "shouldContentBeEliminated method, when receiving 4950000000 likes and 10050000000 dislikes, should return true (0.67 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(25, 75),
            true, 
            "shouldContentBeEliminated method, when receiving 25 likes and 75 dislikes, should return true (0.6651 is higher than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(80,107),
            true, 
            "shouldContentBeEliminated method, when receiving 80 likes and 107 dislikes, should return true (0.501 is higher than 0.5)"
        );

        //false cases
        Assert.equal(
            utils.shouldContentBeEliminated(6, 1),
            false, 
            "shouldContentBeEliminated method, when receiving 6 likes and 1 dislikes, should return false (result will be negative)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(15, 1),
            false, 
            "shouldContentBeEliminated method, when receiving 15 likes and 1 dislikes, should return false (result will be negative)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(10, 8),
            false, 
            "shouldContentBeEliminated method, when receiving 10 likes and 8 dislikes, should return false (0.2148865106 is lesser than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(20, 5),
            false, 
            "shouldContentBeEliminated method, when receiving 20 likes and 5 dislikes, should return false (0.0432 is lesser than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(420, 280),
            false, 
            "shouldContentBeEliminated method, when receiving 420 likes and 280 dislikes, should return false (0.36 is lesser than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(8, 0),
            false, 
            "shouldContentBeEliminated method, when receiving 8 likes and 0 dislikes, should return false (because there are no dislikes)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(44, 56),
            false, 
            "shouldContentBeEliminated method, when receiving 44 likes and 56 dislikes, should return false (0.4627 is lesser than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(9759000000, 5241000000),
            false, 
            "shouldContentBeEliminated method, when receiving 5241000000 likes and 9759000000 dislikes, should return false (0.3494 is lesser than 0.5)"
        );
        Assert.equal(
            utils.shouldContentBeEliminated(80, 106),
            false, 
            "shouldContentBeEliminated method, when receiving 80 likes and 106 dislikes, should return false (0.498738 is lesser than 0.5)"
        );
    }

    function shouldContentBeEliminatedShouldRevert() public {
        //pass as parameters 2 likes, 2 dislikes (4 votes in total) and 6 for minimum quorum
        try utils.shouldContentBeEliminated(2,2) {
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Minimum quorum not reached", 
                "In the shouldContentBeEliminated method if the total number of votes (likes plus dislikes) are less than the minimumQuorum the transaction should be reverted");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
        //pass as parameters 3 likes, 2 dislikes (5 votes in total) and 6 for minimum quorum
        try utils.shouldContentBeEliminated(3,2) {
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Minimum quorum not reached", 
                "In the shouldContentBeEliminated method if the total number of votes (likes plus dislikes) are less than the minimumQuorum the transaction should be reverted");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
    }

    function calculateReward() public {
        Assert.equal(
            utils.calculateReward(10),
            10000000000000000000, 
            "calculateReward method, when receiving 10 users as parameter, should return 10"
        );
        Assert.equal(
            utils.calculateReward(16),
            3906250000000000000, 
            "calculateReward method, when receiving 10 users as parameter, should return 3.906250"
        );
        Assert.equal(
            utils.calculateReward(10305168),
            9416507,
            "calculateReward method, when receiving 10,305,168 users as parameter, should return 0.000000000009416507"
        );
        Assert.equal(
            utils.calculateReward(10305168),
            9416507,
            "calculateReward method, when receiving 10,305,168 users as parameter, should return 0.000000000009416507"
        );
        Assert.equal(
            utils.calculateReward(0),
            1000000000000000000000,
            "calculateReward method, when receiving 0 users as parameter, should return 1000"
        );
    }

    function calculateFee() public {
        Assert.equal(
            utils.calculateFee(10),
            13333333333333333330, 
            "calculateFee method, when receiving 10 users as parameter, should return 13.333333"
        );
        Assert.equal(
            utils.calculateFee(16),
            5208333333333333332, 
            "calculateFee method, when receiving 10 users as parameter, should return 5.2083332"
        );
        Assert.equal(
            utils.calculateFee(10305168),
            12555343, 
            "calculateFee method, when receiving 10,305,168 users as parameter, should return 0.00000000001255534275"
        );
        Assert.equal(
            utils.calculateFee(0),
            1333333333333333333000,
            "calculateFee method, when receiving 0 users as parameter, should return the commissionByBaseReward"
        );
    }

    function isValidUserName() public {
        bytes15[5] memory mockData = [
            bytes15(0x6e756c6c6174746865656e64313200), //nullattheend12
            0x616e6f726d616c757365726e616d65, //anormalusername
            0x6e756d626572733132333435360000,  //numbers123456
            0x616263310000000000000000000000, //abc1
            0x757365725f6e616d655f3100000000 //user_name_1
        ];

        for(uint256 i = 0; i < mockData.length; i++) {
            Assert.ok(
                utils.isValidUserName(mockData[i]), 
                "When using isValidUserName method, the return should be true if the received parameter is a username with at least 4 chars, only lower case letters, numbers and underscores"
            );
        }
    }

    function isValidUserNameShouldRevert() public {
        try utils.isValidUserName(bytes15(0x000000000000000000000000000000)) {
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "User name is empty", 
                "When using isValidUserName method, transaction would revert if the received parameter is null");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x5550504552434153454e414d454565)) { //UPPERCASENAMEEe
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Forbidden character in username", 
                "When using isValidUserName method, transaction would revert if the received username has upper case characters");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x696e76406c696425757365726e616d)) { //inv@lid%usernam
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Forbidden character in username", 
                "When using isValidUserName method, transaction would revert if the received username has special characters, except _ (underscore)");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x757365727769746820737061636565)) { //userwith spacee
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Forbidden character in username", 
                "When using isValidUserName method, transaction would revert if the received username has a blank space");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x6e756c6c76616c7565006265747765)) { //nullvalue betwe
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Null value in between username", 
                "When using isValidUserName method, transaction would revert if the received username has a null value in between");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x006e756c6c61747468657374617274)) { // nullatthestart
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Null value in between username", 
                "When using isValidUserName method, transaction would revert if the received username has a null value at the start");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }

        try utils.isValidUserName(bytes15(0x616263000000000000000000000000)) { //abc
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "At least 4 characters", 
                "When using isValidUserName method, transaction would revert if the received username has less than 4 characters");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
    }

    function calculateFeeForUsersWithStrikes() public {
        Assert.equal(
            utils.calculateFeeForUsersWithStrikes(1, 5),
            159999999999999999960, 
            "calculateFeeForUsersWithStrikes method and receiving 1 strike and 5 users as parameters, should return 159999999999999999960"
        );
        Assert.equal(
            utils.calculateFeeForUsersWithStrikes(2, 5),
            319999999999999999920, 
            "calculateFeeForUsersWithStrikes method and receiving 2 strikes and 5 users as parameters, should return 319999999999999999920"
        );
        Assert.equal(
            utils.calculateFeeForUsersWithStrikes(1, 8000000000),
            60, 
            "calculateFeeForUsersWithStrikes method and receiving 1 strike and 8000000000 users as parameters, should return 60"
        );
        Assert.equal(
            utils.calculateFeeForUsersWithStrikes(7, 300000),
            311111111094, 
            "calculateFeeForUsersWithStrikes method and receiving 7 strikes and 300000 users as parameters, should return 311111111094"
        );        
    }

    function calculateFeeForUsersWithStrikesShouldRevert() public {
        try utils.calculateFeeForUsersWithStrikes(0, 15000) { //pass a zero in the numbero of strikes
            Assert.ok(false, 'method execution should fail');
        } catch Error(string memory reason) {
            Assert.equal(
                reason, 
                "Strikes not greater than zero", 
                "When using the calculateFeeForUsersWithStrikes method, the number of strikes that it receives should be greater than zero");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'failed unexpected');
        }
    }

    function calculateFeeToBurn() public {
        Assert.equal(
            utils.calculateFeeToBurn(140000000000000000000),
            35000000000000000000, 
            "CalculateFeeToBurn when receiving 140000000000000000000 as fee, should return 35000000000000000000"
        );
        Assert.equal(
            utils.calculateFeeToBurn(4),
            1, 
            "CalculateFeeToBurn when receiving 4 as fee, should return 1"
        );
        Assert.equal(
            utils.calculateFeeToBurn(0),
            0, 
            "CalculateFeeToBurn when receiving 0 as fee, should return 0"
        );
    }

}