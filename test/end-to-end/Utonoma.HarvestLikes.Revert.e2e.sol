// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaHarvestLikesRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA; // voter
    address private userB; // content creator

    uint256 private constant INITIAL_SUPPLY = 5_000_000 * 1e18;
    uint256 private constant TOKENS_TO_USER_A = 100_000 * 1e18;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // Deploy Utonoma with a large initial supply to the owner
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);

        // Step 1) Owner transfers 100,000 NOMX to user A
        utonoma.transfer(userA, TOKENS_TO_USER_A);

        // Step 2) User B uploads a content (no fee, no strikes)
        vm.prank(userB);
        bytes32 contentHash = keccak256("content-hash");
        bytes32 metadataHash = keccak256("metadata-hash");
        utonoma.upload(contentHash, metadataHash, ContentStorage.ContentTypes.videos);
    }

    function testHarvestLikes_RevertsInExpectedOrder() public {
        // We always operate over the first content in the videos library (index 0)
        ContentStorage.Identifier memory id =
            ContentStorage.Identifier(0, ContentStorage.ContentTypes.videos);

        // ─────────────────────────────────────────────────────────
        // Step 3) User A sends 6 dislikes to User B's content
        //         -> likes = 0, dislikes = 6
        // ─────────────────────────────────────────────────────────
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userA);
            utonoma.dislike(id);
        }

        // Sanity check: with 0 likes and 6 dislikes,
        // the statistical rule should mark the content as eliminated.
        bool eliminated = utonoma.shouldContentBeEliminated(0, 6);
        assertTrue(eliminated, "Content should be eliminated with 0 likes and 6 dislikes");

        // Step 4) First harvest → reverts by "Content should be eliminated"
        vm.prank(userB);
        vm.expectRevert(bytes("Content should be eliminated"));
        utonoma.harvestLikes(id);

        // ─────────────────────────────────────────────────────────
        // Step 5) User A sends 6 likes:
        //         -> likes = 6, dislikes = 6
        // ─────────────────────────────────────────────────────────
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userA);
            utonoma.like(id);
        }

        // Step 6) Now it should revert with "Likes should be greater than dislikes"
        vm.prank(userB);
        vm.expectRevert(bytes("Likes should be greater than dislikes"));
        utonoma.harvestLikes(id);

        // ─────────────────────────────────────────────────────────
        // Step 7) User A sends 1 more like:
        //         -> likes = 7, dislikes = 6
        // ─────────────────────────────────────────────────────────
        vm.prank(userA);
        utonoma.like(id);

        // Optional sanity check: content should NOT be eliminated now.
        bool eliminatedAfter = utonoma.shouldContentBeEliminated(7, 6);
        assertFalse(eliminatedAfter, "Content should not be eliminated with 7 likes and 6 dislikes");

        // ─────────────────────────────────────────────────────────
        // Step 8) First successful harvest
        // ─────────────────────────────────────────────────────────
        vm.prank(userB);
        utonoma.harvestLikes(id);

        Utonoma.Content memory contentAfterFirstHarvest = utonoma.getContentById(id);
        assertEq(
            contentAfterFirstHarvest.harvestedLikes,
            1,
            "harvestedLikes should be 1 after the first successful harvest"
        );

        // ─────────────────────────────────────────────────────────
        // Step 9) Second harvest → "There are no more likes to harvest"
        // ─────────────────────────────────────────────────────────
        vm.prank(userB);
        vm.expectRevert(bytes("There are no more likes to harvest"));
        utonoma.harvestLikes(id);
    }

    /**
    * @dev This test covers the scenario where a content creator gets its content deleted
    * and later tries to harvest likes on that deleted content.
    */
    function testHarvestLikes_AfterDeletion_RevertsMintToZero() public {
        ContentStorage.Identifier memory id =
            ContentStorage.Identifier(0, ContentStorage.ContentTypes.videos);

        // 1) User A sends 6 dislikes → content should be eligible for deletion
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userA);
            utonoma.dislike(id);
        }

        bool eliminated = utonoma.shouldContentBeEliminated(0, 6);
        assertTrue(eliminated, "Content should be eliminated with 0 likes and 6 dislikes");

        // 2) User A calls deletion → content is cleared, contentOwner becomes address(0)
        vm.prank(userA);
        utonoma.deletion(id);

        Utonoma.Content memory afterDeletion = utonoma.getContentById(id);
        assertEq(afterDeletion.contentOwner, address(0), "contentOwner should be cleared after deletion");

        // 3) Now User A sends 15 likes to the SAME id.
        //    This fills the slot again but keeps contentOwner == address(0),
        //    because like() never sets contentOwner.
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(userA);
            utonoma.like(id);
        }

        Utonoma.Content memory afterLikes = utonoma.getContentById(id);
        assertEq(afterLikes.likes, 15, "There should be 15 likes stored in the deleted slot");
        assertEq(afterLikes.contentOwner, address(0), "Owner must remain zero after deletion + likes");

        // 4) Original creator (userB) tries to harvest likes on this id.
        vm.prank(userB);
        vm.expectRevert("ERC20InvalidReceiver(0x0000000000000000000000000000000000000000)");
        utonoma.harvestLikes(id);
    }

    /**
    * @dev This test covers the scenario where a content creator voluntarily 
    * deletes a content and later tries to harvest likes on that deleted content.
    */
    function testHarvestLikes_AfterVoluntaryDeletion_RevertsMintToZero() public {
        // 1) User B uploads a SECOND content in the same library
        vm.prank(userB);
        bytes32 contentHash2 = keccak256("content-hash-2");
        bytes32 metadataHash2 = keccak256("metadata-hash-2");
        utonoma.upload(contentHash2, metadataHash2, ContentStorage.ContentTypes.videos);

        // This second content should be at index 1 of the videos library
        ContentStorage.Identifier memory id2 =
            ContentStorage.Identifier(1, ContentStorage.ContentTypes.videos);

        Utonoma.Content memory beforeVolDeletion = utonoma.getContentById(id2);

        // 2) User B voluntarily deletes this second content
        vm.prank(userB);
        utonoma.voluntarilyDelete(id2);

        Utonoma.Content memory afterVolDeletion = utonoma.getContentById(id2);
        assertNotEq(afterVolDeletion.contentOwner, beforeVolDeletion.contentOwner, "Content should differ after voluntary deletion");
        assertEq(
            afterVolDeletion.contentOwner,
            address(0),
            "contentOwner should be cleared after voluntary deletion"
        );

        // 3) User A sends 15 likes to the deleted slot
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(userA);
            utonoma.like(id2);
        }

        Utonoma.Content memory afterLikes = utonoma.getContentById(id2);
        assertEq(afterLikes.likes, 15, "There should be 15 likes stored in the voluntarily-deleted slot");
        assertEq(afterLikes.contentOwner, address(0), "Owner must remain zero after voluntary deletion + likes");

        // 4) Original creator (userB) tries to harvest
        //    → again we end trying to mint to address(0)
        vm.prank(userB);
        vm.expectRevert(bytes("ERC20InvalidReceiver(0x0000000000000000000000000000000000000000)"));
        utonoma.harvestLikes(id2);
    }
}
