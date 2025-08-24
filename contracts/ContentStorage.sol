// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

contract ContentStorage {

    enum ContentTypes {
        audios,
        music,
        podcasts,
        audioLivestreams,
        videos,
        shortVideos,
        movies,
        videoLivestreams,
        comments,
        blogs,
        books,
        images,
        animations,
        videoGames,
        apps
    }

    struct Identifier {
        uint256 index;
        ContentTypes contentType;
    }

    struct Content {
        address contentOwner;
        bytes32 contentHash;
        bytes32 metadataHash;
        uint64 likes;
        uint64 dislikes;
        uint64 harvestedLikes;
        uint256[] replyingTo;
        uint8[] replyingToContentType;
        uint256[] repliedBy;
        uint8[] repliedByContentType;
    }

    Content[][15] internal _contentLibraries;

    /// @notice gets the highest value (as integer) that the ContentTypes struct can take
    function getMaxContentTypes() public pure returns(uint256) {
        return uint256(type(ContentTypes).max);
    }

    /** 
    * @notice gets how many contents has been uploaded to a content library 
    * (each content type it's a different library)
    */
    function getContentLibraryLength(ContentTypes contentType) public view returns(uint256){
        return _contentLibraries[uint256(contentType)].length;
    }

    /// @notice gets all the information of a content, searching by it's Identifier
    function getContentById(Identifier memory id) 
        public 
        view 
        contentShouldExists(id)
        returns(Content memory) {
        return _contentLibraries[uint256(id.contentType)][id.index];
    }

    /**
    * @dev Gets an array containing the ids from the contents that are being replied by this one. 
    * As it's not possible to store a dynamic array of Identifier structs, we store the index and the 
    * contentType by separate in the Content struct (by the names of replyingTo and replyingToContentType) 
    * and we recreate the original Identifier struct of each reply, to later append all of them in an array
    * by using the for loop
    */
    function getContentsRepliedByThis(Identifier memory id) 
        public 
        view 
        contentShouldExists(id)
        returns(Identifier[] memory) {
        uint256 replyingToLength = _contentLibraries[uint256(id.contentType)][id.index].replyingTo.length;
        Identifier[] memory contentsRepliedByThis = new Identifier[](replyingToLength);
        for(uint256 i = 0; i < replyingToLength; i++) {
            contentsRepliedByThis[i] = Identifier(
                _contentLibraries[uint256(id.contentType)][id.index].replyingTo[i],
                ContentTypes(_contentLibraries[uint256(id.contentType)][id.index].replyingToContentType[i])
            );
        }
        return contentsRepliedByThis;
    }

    /**
    * @dev Gets an array containing the ids from the contents that are replying this one. 
    * As it's not possible to store a dynamic array of Identifier structs, we store the index and the 
    * contentType by separate in the Content struct (by the names of repliedBy and repliedByContentType) 
    * and we recreate the original Identifier struct of each reply, to later append all of them in an array
    * by using the for loop
    */
    function getRepliesToThisContent(Identifier memory id) 
        public 
        view 
        contentShouldExists(id)
        returns(Identifier[] memory) {
        uint256 repliedByLength = _contentLibraries[uint256(id.contentType)][id.index].repliedBy.length;
        Identifier[] memory repliesToThisContent = new Identifier[](repliedByLength);
        for(uint256 i = 0; i < repliedByLength; i++) {
            repliesToThisContent[i] = Identifier(
                _contentLibraries[uint256(id.contentType)][id.index].repliedBy[i],
                ContentTypes(_contentLibraries[uint256(id.contentType)][id.index].repliedByContentType[i])
            );
        }
        return repliesToThisContent;
    }
    
    /// @dev Creates a new content in the specified content library. Returns the id of this new content
    /// @return Identifier in wich the content was stored
    function _createContent(Content memory content, ContentTypes contentType) internal returns(Identifier memory) {
        _contentLibraries[uint256(contentType)].push(content);
        return Identifier(getContentLibraryLength(contentType) - 1, contentType);
    }

    /// @dev sets one content to be a reply of another one.
    /// @param replyId is the content that is replying
    /// @param replyingToId is the content that wants to be replied by the other
    /**
    * @notice identifier struct can't be stored like this, so it has to be separated in it's index and 
    * content library components, original identifier can be restored and retrived by using their 
    * respective getters (getContentsRepliedByThis and getRepliesToThisContent)
    */
    function _createReply(
        Identifier memory replyId, 
        Identifier memory replyingToId
    ) internal 
        contentShouldExists(replyId) 
        contentShouldExists(replyingToId)  {
        _contentLibraries[uint256(replyId.contentType)][replyId.index].replyingTo.push(replyingToId.index);
        _contentLibraries[uint256(replyId.contentType)][replyId.index].replyingToContentType.push(uint8(replyingToId.contentType));

        _contentLibraries[uint256(replyingToId.contentType)][replyingToId.index].repliedBy.push(replyId.index);
        _contentLibraries[uint256(replyingToId.contentType)][replyingToId.index].repliedByContentType.push(uint8(replyId.contentType));
    }    

    function _updateContent(Content memory content, Identifier memory id) 
        internal 
        contentShouldExists(id) {
        _contentLibraries[uint256(id.contentType)][id.index] = content;
    }

    function _deleteContent(Identifier memory id) 
        internal 
        contentShouldExists(id) {
        delete(_contentLibraries[uint256(id.contentType)][id.index]);
    }

    modifier contentShouldExists(Identifier memory id) {
        require(id.index < _contentLibraries[uint256(id.contentType)].length, "Out of index");
        _;
    }

}