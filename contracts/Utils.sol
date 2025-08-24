// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Utils {

    uint256 private constant _BASE_REWARD = 1000;
    //uint256 internal constant _commission = 1333333333333333333; //1.333333333333333333% of commission
    //If the values of the _BASE_REWARD or _commission changes, the next const should also be recalculated
    uint256 private constant _COMMISSION_BY_BASE_REWARD = 1333333333333333333000;
    uint256 private constant _MINIMUM_QUORUM = 5;

    /// @notice please refer to the Utonoma paper to know what the base reward is
    function baseReward() external pure returns (uint256) {
        return _BASE_REWARD;
    }

    /// @notice precomputed multiplication of the commision by the base reward stored to save calculations
    function commissionByBaseReward() external pure returns(uint256) {
        return _COMMISSION_BY_BASE_REWARD;
    }

    /// @notice minimum amount of votes (likes and dislikes) that should be emited to grant a reward
    function minimumQuorum() external pure returns(uint256) {
        return _MINIMUM_QUORUM;
    }


    /**
    * @dev Receives the number of likes, dislikes and the minimum quorum required to deliverate about a content
    * returns the true if the content should be eliminated, false if not. 
    * 
    * It does it by calculated the upper limit of the confidence interval and compairing it with 1/2, that is 
    * the proportion of negative votes that will cause the content to be eliminated. 
    * https://en.wikipedia.org/wiki/Confidence_interval.
    */
    function shouldContentBeEliminated(uint256 likes, uint256 dislikes) public pure returns(bool) {
        uint256 likesPlusDislikes = (likes + dislikes);
        require(likesPlusDislikes > _MINIMUM_QUORUM, "Minimum quorum not reached");
        if(dislikes == 0) return false;
        uint256 normalizedDislikes = dislikes * 10**18;
        uint256 p = normalizedDislikes / likesPlusDislikes;
        uint256 oneMinusP = 1e18 - p;
        uint256 pByOneMinusP = p * oneMinusP;
        uint256 n = likesPlusDislikes * 10**18;
        uint256 pByOneMinusPBetweenN = pByOneMinusP / n;
        uint256 root = Math.sqrt(pByOneMinusPBetweenN);
        uint256 z = 1.96e18;
        uint256 rootByZ = (root * z) / 10**9;
        uint256 pMinusRootByZ;
        unchecked{
            pMinusRootByZ = p - rootByZ;
        }
        if(pMinusRootByZ > p) return false;
        uint256 oneHalf = 5e17;
        
        return pMinusRootByZ > oneHalf;
    }

    /// @notice calculates the reward that a content creator can receive for one like, if the users number is 0, will return 10**18 * _BASE_REWARD
    /// @param usersNumber the current monthly active users (MAU) that the platform has
    function calculateReward(uint256 usersNumber) public pure returns(uint256) {
        if(usersNumber == 0) return (10**18 * _BASE_REWARD);
        return (10**18 * _BASE_REWARD) / usersNumber**2;
    }

    /// @notice calculates the fee, if the number of users is 0, will return _COMMISSION_BY_BASE_REWARD
    /// @param usersNumber the current monthly active users (MAU) that the platform has
    function calculateFee(uint256 usersNumber) public pure returns(uint256) {
        if(usersNumber == 0) return (_COMMISSION_BY_BASE_REWARD);
        return _COMMISSION_BY_BASE_REWARD / usersNumber**2;
    }

    /**
    *  @notice calculates the fee for any particular number of strikes, result grows based
    *  in the strikes number
    */ 
    function calculateFeeForUsersWithStrikes(uint64 numberOfStrikes, uint256 usersNumber) public pure returns(uint256) {
        require(numberOfStrikes > 0, "Strikes not greater than zero"); 
        return 3 * calculateFee(usersNumber) * numberOfStrikes;
    }

    /**
    *  @notice Calculates the amount of tokens to burn based on the given fee.
    *  @param fee The total fee from which the burn amount will be calculated.
    *  @return The amount of tokens to be burned.
    */ 
    function calculateFeeToBurn(uint256 fee) public pure returns (uint256) {
        return fee / 4;
    }

    /**
    *  @notice checks if a username it's valid (only lower case letters, numbers, and underscores, 
    *  min 4 chars and less than 15)
    */ 
    /// @dev Validates by comparing the bytes32 with the ascii symbols they represent in hex
    function isValidUserName(bytes15 userName) public pure returns(bool) {
        require(userName != 0x0, "User name is empty");

        uint256 numberOfCharacters;
        bool nullSpace;
        bool charAfterNullSpace;
        for(uint256 i = 0; i < 15; i++) {
            if(userName[i] == 0x00) nullSpace = true;
            if(nullSpace && userName[i] != 0x00) charAfterNullSpace = true;

            require(
                userName[i] == 0x00 ||
                userName[i] == 0x5F ||
                (userName[i] >= 0x30 && userName[i] <= 0x39) ||
                (userName[i] >= 0x61 && userName[i] <= 0x7A),
                "Forbidden character in username"
            );

            if(userName[i] != 0x00) numberOfCharacters++;
        }

        require(numberOfCharacters > 3, "At least 4 characters");
        require(!charAfterNullSpace, "Null value in between username");

        return true;
    }
}
