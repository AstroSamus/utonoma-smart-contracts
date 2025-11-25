// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {ContentStorage} from "../contracts/ContentStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
* works with external calls, but _createContent and other methods from this contracts are 
* internal, so we need to expose them here. 
* To call these methods you need to call them by using this.methodName(...) so it is an external call.
*/
contract ContentStorageHarness is ContentStorage {
    function createContentForTest(Content memory content, ContentTypes contentType)
        external
        returns (Identifier memory)
    {
        return _createContent(content, contentType);
    }

    function createReplyForTest(Identifier memory replyId, Identifier memory replyingToId) external {
        _createReply(replyId, replyingToId);
    }

    function updateContentForTest(Content memory content, Identifier memory id) external {
        _updateContent(content, id);
    }

    function deleteContentForTest(Identifier memory id) external {
        _deleteContent(id);
    }
}

contract ContentStorageTest is Test, Comparators {
    using Strings for uint256;

    ContentStorageHarness internal contentStorage;

    bytes32 contentHash = 0x017dfd85d4f6cb4dcd715a88101f7b1f06cd1e009b2327a0809d01eb9c91f231;
    bytes32 metadataHash = 0x7465737400000000000000000000000000000000000000000000000000000000;

    address account0 = address(0xA0);
    address account1 = address(0xA1);

    function setUp() public {
        contentStorage = new ContentStorageHarness();
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _buildSampleContent(address owner)
        internal
        view
        returns (ContentStorage.Content memory)
    {
        return ContentStorage.Content({
            contentOwner: owner,
            contentHash: contentHash,
            metadataHash: metadataHash,
            likes: 0,
            dislikes: 0,
            harvestedLikes: 0,
            replyingTo: new uint256[](0),
            replyingToContentType: new uint8[](0),
            repliedBy: new uint256[](0),
            repliedByContentType: new uint8[](0)
        });
    }

    function AssertEqualUint(uint256 a, uint256 b, string memory message) internal pure {
        assertEq(a, b, message);
    }

    function AssertEqualAddress(address a, address b, string memory message) internal pure {
        assertEq(a, b, message);
    }

    function AssertEqualBytes32(bytes32 a, bytes32 b, string memory message) internal pure {
        assertEq(a, b, message);
    }

    function AssertOk(bool condition, string memory message) internal pure {
        require(condition, message);
    }

    function AssertNotEqualAddress(address a, address b, string memory message) internal pure {
        require(a != b, message);
    }

    function AssertNotEqualUint(uint256 a, uint256 b, string memory message) internal pure {
        require(a != b, message);
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    function testInitialContentLibrariesAreEmpty() public view {
        uint256 max = contentStorage.getMaxContentTypes();
        for (uint256 i = 0; i <= max; i++) {
            ContentStorage.ContentTypes ct = ContentStorage.ContentTypes(i);
            uint256 length = contentStorage.getContentLibraryLength(ct);

            AssertEqualUint(
                length,
                0,
                string.concat(
                    "Content Library ",
                    i.toString(),
                    " should have length of 0 when the contract just has been deployed"
                )
            );
        }
    }

    function testCreateContentSuccess() public {
        uint256 max = contentStorage.getMaxContentTypes();

        for (uint256 i = 0; i <= max; i++) {
            ContentStorage.ContentTypes ct = ContentStorage.ContentTypes(i);

            uint256 originalLibraryLength = contentStorage.getContentLibraryLength(ct);

            ContentStorage.Content memory sampleContent = _buildSampleContent(account0);

            ContentStorage.Identifier memory createdContentId =
                contentStorage.createContentForTest(sampleContent, ct);

            uint256 modifiedLibraryLength = contentStorage.getContentLibraryLength(ct);

            ContentStorage.Identifier memory lastId = ContentStorage.Identifier({
                index: modifiedLibraryLength - 1,
                contentType: ct
            });

            ContentStorage.Content memory insertedContent =
                contentStorage.getContentById(lastId);

            AssertEqualUint(
                modifiedLibraryLength,
                originalLibraryLength + 1,
                string.concat(
                    "When using the createContent method, the size of the contentLibrary ",
                    i.toString(),
                    " should be increased by one"
                )
            );

            AssertEqualUint(
                createdContentId.index,
                modifiedLibraryLength - 1,
                "When using the createContent method, the identifier returned by the method should have an index corresponding to the length of the content library - 1"
            );

            AssertEqualUint(
                uint8(createdContentId.contentType),
                uint8(ct),
                "When using the createContent method, the identifier returned by the method should have a contentType corresponding to the content library that holds the content"
            );

            AssertEqualAddress(
                insertedContent.contentOwner,
                account0,
                "When using the createContent method, the address stored in 'contentOwner' should be the same that was used as message sender"
            );

            AssertEqualBytes32(
                insertedContent.contentHash,
                contentHash,
                "When using the createContent method, the hash stored in 'contentHash' should be the same that was provided in the parameter 'contentHash' to the method"
            );

            AssertEqualBytes32(
                insertedContent.metadataHash,
                metadataHash,
                "When using the createContent method, the hash stored in 'metadataHash' should be the same that was provided in the parameter 'metadataHash' to the method"
            );
        }
    }

    function testCreateReplySuccess() public {
        // Create 3 contents with different content types
        ContentStorage.Content memory sample = _buildSampleContent(account0);

        ContentStorage.Identifier memory contentId1 =
            contentStorage.createContentForTest(sample, ContentStorage.ContentTypes(6));
        ContentStorage.Identifier memory contentId2 =
            contentStorage.createContentForTest(sample, ContentStorage.ContentTypes(11));
        ContentStorage.Identifier memory contentId3 =
            contentStorage.createContentForTest(sample, ContentStorage.ContentTypes(10));

        uint256 originalRepliesToContent1Length =
            contentStorage.getRepliesToThisContent(contentId1).length;

        // Content 2 should reply to 1
        contentStorage.createReplyForTest(contentId2, contentId1);
        // Content 3 should reply to 1
        contentStorage.createReplyForTest(contentId3, contentId1);

        ContentStorage.Identifier[] memory repliesToContent1 =
            contentStorage.getRepliesToThisContent(contentId1);

        // Check that content 2 is in the list of replies of content 1
        bool is2InTheListOfReplies = false;
        for (uint256 i = 0; i < repliesToContent1.length; i++) {
            if (
                repliesToContent1[i].index == contentId2.index
                    && uint256(repliesToContent1[i].contentType)
                        == uint256(contentId2.contentType)
            ) {
                is2InTheListOfReplies = true;
                break;
            }
        }

        AssertOk(
            is2InTheListOfReplies,
            "When using the method createReply to reply content 1 with content 2, the list of replies to content 1 should contain the id of content 2"
        );

        AssertEqualUint(
            repliesToContent1.length,
            originalRepliesToContent1Length + 2,
            "When using the method createReply to reply two times to content 1, the length of the array of replies to content 1 should increase by 2"
        );

        // Content 4
        ContentStorage.Identifier memory contentId4 =
            contentStorage.createContentForTest(sample, ContentStorage.ContentTypes(8));

        uint256 originalContentsRepliedBy4Length =
            contentStorage.getContentsRepliedByThis(contentId4).length;

        // Content 4 replies to 1, 2 and 3
        contentStorage.createReplyForTest(contentId4, contentId1);
        contentStorage.createReplyForTest(contentId4, contentId2);
        contentStorage.createReplyForTest(contentId4, contentId3);

        ContentStorage.Identifier[] memory contentsRepliedBy4 =
            contentStorage.getContentsRepliedByThis(contentId4);

        // Check that content 1 is in the list of contents replied by 4
        bool is1InTheList = false;
        for (uint256 i = 0; i < contentsRepliedBy4.length; i++) {
            if (
                contentsRepliedBy4[i].index == contentId1.index
                    && uint256(contentsRepliedBy4[i].contentType)
                        == uint256(contentId1.contentType)
            ) {
                is1InTheList = true;
                break;
            }
        }

        AssertOk(
            is1InTheList,
            "When using the method createReply to reply content 1 with content 4, the list of contents replied by content 4 should contain the id of content 1"
        );

        AssertEqualUint(
            contentsRepliedBy4.length,
            originalContentsRepliedBy4Length + 3,
            "When using the method createReply to reply three contents with content 4, the length of the array of contents replied by 4 should increase by three"
        );
    }

    function testUpdateContentSuccess() public {
        // Create a content to be modified later
        ContentStorage.Content memory originalToInsert = _buildSampleContent(account1);
        ContentStorage.ContentTypes ct = ContentStorage.ContentTypes(0);

        ContentStorage.Identifier memory targetContentIdentifier =
            contentStorage.createContentForTest(originalToInsert, ct);

        ContentStorage.Content memory originalContent =
            contentStorage.getContentById(targetContentIdentifier);

        bytes32 modifiedContentHash =
            0x017dfd85d4f6cb4dcd715a88101f7b1f06cd1e009b2327a0809d888777555555;
        bytes32 modifiedMetadataHash =
            0x7465737400000000000000000000000000000000000000000000222222111111;

        ContentStorage.Content memory content2 = ContentStorage.Content({
            contentOwner: account1,
            contentHash: modifiedContentHash,
            metadataHash: modifiedMetadataHash,
            likes: originalContent.likes + 1,
            dislikes: originalContent.dislikes + 1,
            harvestedLikes: originalContent.harvestedLikes + 1,
            replyingTo: new uint256[](0),
            replyingToContentType: new uint8[](0),
            repliedBy: new uint256[](0),
            repliedByContentType: new uint8[](0)
        });

        contentStorage.updateContentForTest(content2, targetContentIdentifier);

        ContentStorage.Content memory modifiedContent =
            contentStorage.getContentById(targetContentIdentifier);

        // contentHash
        AssertNotEqualUint(
            uint256(modifiedContent.contentHash),
            uint256(originalContent.contentHash),
            "When using the updateContent method to modify the value of the contentHash, it should be different from the original one"
        );
        AssertEqualBytes32(
            modifiedContent.contentHash,
            content2.contentHash,
            "When using the updateContent method to modify the contentHash the new value should be equal to the updated information"
        );

        // metadataHash
        AssertNotEqualUint(
            uint256(modifiedContent.metadataHash),
            uint256(originalContent.metadataHash),
            "When using the updateContent method to modify the value of the metadataHash, it should be different from the original one"
        );
        AssertEqualBytes32(
            modifiedContent.metadataHash,
            content2.metadataHash,
            "When using the updateContent method to modify the metadataHash the new value should be equal to the updated information"
        );

        // likes
        AssertNotEqualUint(
            modifiedContent.likes,
            originalContent.likes,
            "When using the updateContent method to modify the value of the likes, it should be different from the original one"
        );
        AssertEqualUint(
            modifiedContent.likes,
            content2.likes,
            "When using the updateContent method to modify the likes the new value should be equal to the updated information"
        );

        // dislikes
        AssertNotEqualUint(
            modifiedContent.dislikes,
            originalContent.dislikes,
            "When using the updateContent method to modify the value of the dislikes, it should be different from the original one"
        );
        AssertEqualUint(
            modifiedContent.dislikes,
            content2.dislikes,
            "When using the updateContent method to modify the dislikes the new value should be equal to the updated information"
        );

        // harvestedLikes
        AssertNotEqualUint(
            modifiedContent.harvestedLikes,
            originalContent.harvestedLikes,
            "When using the updateContent method to modify the value of the harvestedLikes, it should be different from the original one"
        );
        AssertEqualUint(
            modifiedContent.harvestedLikes,
            content2.harvestedLikes,
            "When using the updateContent method to modify the harvestedLikes the new value should be equal to the updated information"
        );
    }

    function testDeleteSuccess() public {
        // Create the content and then delete it
        ContentStorage.Content memory originalToInsert = _buildSampleContent(account0);
        ContentStorage.ContentTypes ct = ContentStorage.ContentTypes(0);

        ContentStorage.Identifier memory targetIdentifier =
            contentStorage.createContentForTest(originalToInsert, ct);

        ContentStorage.Content memory originalContent =
            contentStorage.getContentById(targetIdentifier);
        uint256 originalContentLength =
            contentStorage.getContentLibraryLength(targetIdentifier.contentType);

        contentStorage.deleteContentForTest(targetIdentifier);

        ContentStorage.Content memory storageSpaceAfterDeletion =
            contentStorage.getContentById(targetIdentifier);

        AssertNotEqualAddress(
            originalContent.contentOwner,
            storageSpaceAfterDeletion.contentOwner,
            "When using the deleteContent method, the storage identifier should no longer contain the same information as before"
        );

        AssertEqualUint(
            contentStorage.getContentLibraryLength(targetIdentifier.contentType),
            originalContentLength,
            "When using the deleteContent method, the length of the content library before and after applying the method should be the same"
        );

        AssertEqualAddress(
            storageSpaceAfterDeletion.contentOwner,
            address(0),
            "When using the deleteContent method, the information of the contentOwner should be clear"
        );
        AssertEqualBytes32(
            storageSpaceAfterDeletion.contentHash,
            bytes32(0),
            "When using the deleteContent method, the information of the contentHash should be clear"
        );
        AssertEqualBytes32(
            storageSpaceAfterDeletion.metadataHash,
            bytes32(0),
            "When using the deleteContent method, the information of the metadataHash should be clear"
        );
        AssertEqualUint(
            storageSpaceAfterDeletion.likes,
            0,
            "When using the deleteContent method, the information of the likes should be clear"
        );
        AssertEqualUint(
            storageSpaceAfterDeletion.dislikes,
            0,
            "When using the deleteContent method, the information of the dislikes should be clear"
        );
        AssertEqualUint(
            storageSpaceAfterDeletion.harvestedLikes,
            0,
            "When using the deleteContent method, the information of the harvestedLikes should be clear"
        );
    }
}
