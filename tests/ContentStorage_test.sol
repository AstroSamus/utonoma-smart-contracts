// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "remix_tests.sol";
import "remix_accounts.sol";
import {ContentStorage} from "../contracts/ContentStorage.sol";
import {Comparators} from "tests/test_utils/Comparators.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ContentStorage_test is ContentStorage, Comparators {

    bytes32 contentHash = 0x017dfd85d4f6cb4dcd715a88101f7b1f06cd1e009b2327a0809d01eb9c91f231;
    bytes32 metadataHash = 0x7465737400000000000000000000000000000000000000000000000000000000;
    Content sampleContent = Content(
        msg.sender,
        contentHash,
        metadataHash,
        0,
        0,
        0,
        new uint256[](0),
        new uint8[](0),
        new uint256[](0),
        new uint8[](0)
    );

    function beforeAll() public {
        for(uint256 i = 0; i < getMaxContentTypes(); i++) {
            Assert.equal(
                getContentLibraryLength(ContentStorage.ContentTypes(i)), 
                0, 
                string.concat("Content Library ", Strings.toString(i)," should have length of 0 when the contract just has been deployed")
            );
        }
    }

    /// #sender: account-0
    function createContentSuccess() public {
        for(uint256 i = 0; i < getMaxContentTypes(); i++) { 
            uint256 originalLibraryLength = getContentLibraryLength(ContentTypes(i));
            Identifier memory createdContentId = _createContent(sampleContent, ContentTypes(i));
            
            uint256 modifiedLibraryLength = getContentLibraryLength(ContentTypes(i));
            Content memory insertedContent = getContentById(Identifier(modifiedLibraryLength - 1, ContentTypes(i)));

            Assert.equal(
                modifiedLibraryLength, 
                originalLibraryLength + 1, 
                string.concat(
                    "When using the createContent method, the size of the contentLibrary ", Strings.toString(i)," should be increased by one"
                )
            );

            Assert.equal(
                createdContentId.index, 
                modifiedLibraryLength - 1, 
                "When using the createContent method, the identifier returned by the method should have an index corresponding to the length of the content library - 1"
            );

            Assert.equal(
                uint8(createdContentId.contentType), 
                uint8(ContentTypes(i)), 
                "When using the createContent method, the identifier returned by the method should have a contentType corresponding to the content library that holds the content"
            );

            Assert.equal(
                createdContentId.index, 
                modifiedLibraryLength - 1, 
                "When using the createContent method, the identifier returned by the method should have an index corresponding to the length of the content library - 1"
            );

            Assert.equal(
                insertedContent.contentOwner, 
                TestsAccounts.getAccount(0),
                "When using the createContent method, the address stored in 'contentOwner' should be the same that was used as message sender"
            );

            Assert.equal(
                insertedContent.contentHash, 
                contentHash, 
                "When using the createContent method, the hash stored in 'contentHash' should be the same that was provided in the parameter 'contentHash' to the method"
            );

            Assert.equal(
                insertedContent.metadataHash, 
                metadataHash, 
                "When using the createContent method, the hash stored in 'metadataHash' should be the same that was provided in the parameter 'metadataHash' to the method"
            );
            
        }
    }

    function createReplySuccess() public {

        //Create 3 contents
        Identifier memory contentId1 = _createContent(sampleContent, ContentTypes(6));
        Identifier memory contentId2 = _createContent(sampleContent, ContentTypes(11));
        Identifier memory contentId3 = _createContent(sampleContent, ContentTypes(10));

        uint256 originalRepliesToContent1Length = getRepliesToThisContent(contentId1).length;

        //Content 2 should reply to 1
        _createReply(contentId2, contentId1);
        //Content 3 should reply to 1
        _createReply(contentId3, contentId1);
        Identifier[] memory repliesToContent1 = getRepliesToThisContent(contentId1);
        //Check that content 2 is in the list of replies of content 1
        bool is2InTheListOfReplies = false;
        for(uint256 i = 0; i < repliesToContent1.length; i++) {
            if(repliesToContent1[i].index == contentId2.index && uint256(repliesToContent1[i].contentType) == uint256(contentId2.contentType)) {
                is2InTheListOfReplies = true;
            } 
        }

        Assert.ok(
            is2InTheListOfReplies,
            "When using the method createReply to reply content 1 with content 2, the list of replies to content 1 should contain the id of content 2"
        );

        Assert.equal(
            repliesToContent1.length,
            originalRepliesToContent1Length + 2,
            "When using the method createReply to reply two times to content 1, the length of the array of replies to content 1 should increase by 2"
        );

        Identifier memory contentId4 = _createContent(sampleContent, ContentTypes(8));

        uint256 originalContentsRepliedBy4Length = getContentsRepliedByThis(contentId4).length;

        //Content 4 replies to 1, 2 and 3
        _createReply(contentId4, contentId1);
        _createReply(contentId4, contentId2);
        _createReply(contentId4, contentId3);

        Identifier[] memory contentsRepliedBy4 = getContentsRepliedByThis(contentId4);
        
        //Check that content 1 is in the list of contents replied by 4
        bool isRepliedBy4 = false;
        for(uint256 i = 0; i < repliesToContent1.length; i++) {
            if(repliesToContent1[i].index == contentId2.index && uint256(repliesToContent1[i].contentType) == uint256(contentId2.contentType)) {
                isRepliedBy4 = true;
            } 
        }
        
        Assert.ok(
            isRepliedBy4,
            "When using the method createReply to reply content 1 with content 4, the list of contents replied by content 4 should contain the id of content 1"
        );

        Assert.equal(
            contentsRepliedBy4.length,
            originalContentsRepliedBy4Length + 3,
            "When using the method createReply to reply three contents with content 4, the length of the array of contents replied by 4 should increase by three"
        );
    }

    /// #sender: account-1
    function updateContentSuccess() public {
        Identifier memory targetContentIdentifier = Identifier(0, ContentTypes(0));
        bytes32 modifiedContentHash = 0x017dfd85d4f6cb4dcd715a88101f7b1f06cd1e009b2327a0809d888777555555;
        bytes32 modifiedMetadataHash = 0x7465737400000000000000000000000000000000000000000000222222111111;
        
        Content memory originalContent = getContentById(targetContentIdentifier);
        
        Content memory content2 = Content(
            msg.sender,
            modifiedContentHash,
            modifiedMetadataHash,
            originalContent.likes++,
            originalContent.dislikes++,
            originalContent.harvestedLikes++,
            new uint256[](0),
            new uint8[](0),
            new uint256[](0),
            new uint8[](0)
        );

        _updateContent(content2, targetContentIdentifier);

        Content memory modifiedContent = getContentById(targetContentIdentifier);

        Assert.notEqual(
            modifiedContent.contentHash, 
            originalContent.contentHash, 
            "When using the updateContent method to modify the value of the contentHash, it should be different from the original one"
        );
        Assert.equal(
            modifiedContent.contentHash,
            content2.contentHash, 
            "When using the updateContent method to modify the contentHash the new value should be equal to the updated information"
        );

        Assert.notEqual(
            modifiedContent.metadataHash, 
            originalContent.metadataHash, 
            "When using the updateContent method to modify the value of the metadataHash, it should be different from the original one"
        );
        Assert.equal(
            modifiedContent.metadataHash, 
            content2.metadataHash,
            "When using the updateContent method to modify the metadataHash the new value should be equal to the updated information"
        );

        Assert.notEqual(
            modifiedContent.likes, 
            originalContent.likes, 
            "When using the updateContent method to modify the value of the likes, it should be different from the original one"
        );
        Assert.equal(
            modifiedContent.likes, 
            content2.likes,
            "When using the updateContent method to modify the likes the new value should be equal to the updated information"
        );

        Assert.notEqual(
            modifiedContent.dislikes, 
            originalContent.dislikes, 
            "When using the updateContent method to modify the value of the dislikes, it should be different from the original one"
        );
        Assert.equal(
            modifiedContent.dislikes, 
            content2.dislikes,
            "When using the updateContent method to modify the dislikes the new value should be equal to the updated information"
        );

        Assert.notEqual(
            modifiedContent.harvestedLikes, 
            originalContent.harvestedLikes, 
            "When using the updateContent method to modify the value of the harvestedLikes, it should be different from the original one"
        );
        Assert.equal(
            modifiedContent.harvestedLikes,
            content2.harvestedLikes,
            "When using the updateContent method to modify the harvestedLikes the new value should be equal to the updated information"
        );
    }

    function deleteSuccess() public {
        Identifier memory targetIdentifier = Identifier(0, ContentTypes(0));
        Content memory originalContent = getContentById(targetIdentifier);
        uint256 originalContentLength = getContentLibraryLength(targetIdentifier.contentType);

        _deleteContent(targetIdentifier);
        Content memory storageSpaceAfterDeletion = getContentById(targetIdentifier);

        Assert.notEqual(
            originalContent.contentOwner,
            storageSpaceAfterDeletion.contentOwner,
            "When using the deleteContent method, the storage identifier should no longer contain the same information as before"
        );

        Assert.equal(
            getContentLibraryLength(targetIdentifier.contentType),
            originalContentLength,
            "When using the deleteContent method, the length of the content library before and after applying the method should be the same"
        );

        Assert.equal(
            storageSpaceAfterDeletion.contentOwner,
            address(0),
            "When using the deleteContent method, the information of the contentOwner should be clear"
        );
        Assert.equal(
            storageSpaceAfterDeletion.contentHash,
            0x0,
            "When using the deleteContent method, the information of the contentHash should be clear"
        );
        Assert.equal(
            storageSpaceAfterDeletion.metadataHash,
            0x0,
            "When using the deleteContent method, the information of the metadataHash should be clear"
        );
        Assert.equal(
            storageSpaceAfterDeletion.likes,
            0,
            "When using the deleteContent method, the information of the likes should be clear"
        );
        Assert.equal(
            storageSpaceAfterDeletion.dislikes,
            0,
            "When using the deleteContent method, the information of the dislikes should be clear"
        );
        Assert.equal(
            storageSpaceAfterDeletion.harvestedLikes,
            0,
            "When using the deleteContent method, the information of the harvestedLikes should be clear"
        );

    }
}