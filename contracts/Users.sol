// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {Utils} from "contracts/Utils.sol";

contract Users is Utils {

    /**
    * @notice userMetadataHash is the hash of the content identifier in the ipfs network of a json file
    * that contains information of CIDs in the IPFS network of the user metadata, like the profile picture,
    * nickname, age and other
    */ 
    struct UserProfile{
        uint256 latestInteraction;
        bytes32 userMetadataHash;
        bytes15 userName;
        uint64 strikes; 
    }
    
    mapping(address account => UserProfile) internal _users;
    mapping(bytes15 userName => address account) internal _userNames;

    /// @notice each element from the array corresponds to one month
    uint256[] private _MAU;

    /// @notice gets the user profile of the account
    function getUserProfile(address account) public view returns(UserProfile memory) {
        return _users[account];
    }

    /// @notice gets the account of the owner of a username
    /// @param requestedUserName is the username from wich wants to know the owner's account
    function getUserNameOwner(bytes15 requestedUserName) public view returns(address) {
        return _userNames[requestedUserName];
    }

    /// @notice gets the account of the owner of a user name
    function getLatestInteractionTime(address account) public view returns(uint256) {
        return _users[account].latestInteraction;
    }

    /// @dev Gets the current period MAU calculation
    /** @notice In case that there are no users (nobody has uploaded a content) 
    *   it will return 0. For the first month of work of the application, the return will be the current period
    *   calculation. For the rest of time, the return will be the MAU calculation of the previous period.
    */
    function currentPeriodMAU() public view returns(uint256) {
        if(_MAU.length < 2){
            if(_MAU.length < 1) return 0;
            //for the first month the users number should be the current MAU calculation
            return _MAU[_MAU.length - 1];
        }
        return _MAU[_MAU.length - 2];
    }

    /// @dev Returns all the MAU historic data in an array, each element is one month
    function historicMAUData() public view returns(uint256[] memory) {
        return _MAU;
    }

    /**
    * @notice allows a user to create a unique username, only can contain lower case letters, numbers, and underscores, 
    * min 4 chars and less than 15
    */
    /// @param proposedUserName it's the username that wants to be registered
    /// @param metadata bytes32 of a CID containing the additional information of the user, set it to 0x0 to not incluide it
    function createUser(bytes15 proposedUserName, bytes32 metadata) public {
        isValidUserName(proposedUserName);
        require(getUserProfile(msg.sender).userName == bytes15(0), "Account already have a username");
        require(getUserNameOwner(proposedUserName) == address(0), "Username isn't available");

        _userNames[proposedUserName] = msg.sender;
        _users[msg.sender].userName = proposedUserName;

        if(metadata != bytes32(0)) 
            _users[msg.sender].userMetadataHash = metadata; 
    }

    /** 
    * @notice this method can be used to change the profile picture or other information of the user. 
    * Update the metadata hash to 0x0 to delete the previous information
    */
    /// @param metadata is the new metadata information that will overwrite the existing one
    /// @dev overwrites the userMetadataHash of the msg sender in the _users mapping
    function updateUserMetadataHash(bytes32 metadata) public {
        _users[msg.sender].userMetadataHash = metadata;
    }

    function _addStrike(address contentCreator) internal {
        _users[contentCreator].strikes++;        
    }

    function _logUserInteraction(
        uint256 currentTime, 
        uint256 startTimeOfNetwork
    ) internal {
        uint256 startTimeMinusCurrent = currentTime - startTimeOfNetwork;
        uint256 elapsedMonths = startTimeMinusCurrent / 30 days;

        uint256 MAUArrayLength = _MAU.length;

        //If there are no users during the whole period then fill with 0 in the report
        if(elapsedMonths > MAUArrayLength) {
            uint256 monthsWithNoInteraction = elapsedMonths - MAUArrayLength;
            for(uint i = 0; i < monthsWithNoInteraction; i++) {
                _MAU.push(0);
            }
        }
        
        address account = msg.sender;
        uint256 latestUserInteraction = _users[account].latestInteraction;
        bool shouldCountAsNewInteraction;

        //If the interaction is the first of a new opening period.
        if(elapsedMonths + 1 > MAUArrayLength) {
            _MAU.push(1);
        }

        //if it is the first interaction of the user with the platform
        else if(latestUserInteraction == 0) {shouldCountAsNewInteraction = true;}

        //If the previous interaction was before the begining of the new period
        else {
            uint startTimeOfNewPeriod = startTimeOfNetwork + (30 days * MAUArrayLength);
            if(startTimeOfNewPeriod < latestUserInteraction) {
                shouldCountAsNewInteraction = true;
            }
        }

        if(shouldCountAsNewInteraction) {
            _MAU[MAUArrayLength - 1]++;
        }

        _users[account].latestInteraction = currentTime;
    }
}