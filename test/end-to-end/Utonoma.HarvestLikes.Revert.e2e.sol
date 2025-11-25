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

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // Deploy Utonoma with a large initial supply to the owner
        uint256 INITIAL_SUPPLY = 5_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);

        // Step 1) Owner transfers 100,000 NOMX to user A
        uint256 amountToUserA = 100_000 * 1e18;
        utonoma.transfer(userA, amountToUserA);

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

        // ─────────────────────────────────────────────────────────────
        // Step 3) User A sends 6 dislikes to User B's content
        //         -> likes = 0, dislikes = 6
        // ─────────────────────────────────────────────────────────────
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userA);
            utonoma.dislike(id);
        }

        // Sanity check: with 0 likes and 6 dislikes,
        // the statistical rule should mark the content as eliminated.
        bool eliminated = utonoma.shouldContentBeEliminated(0, 6);
        assertTrue(eliminated, "Content should be eliminated with 0 likes and 6 dislikes");

        // ─────────────────────────────────────────────────────────────
        // Step 4) User B tries to harvest likes:
        //   - First require in harvestLikes is:
        //        require(shouldContentBeEliminated(...) == false, "Content should be eliminated");
        //   - Since the content SHOULD be eliminated here, it must revert
        //     with "Content should be eliminated".
        // ─────────────────────────────────────────────────────────────
        vm.prank(userB);
        vm.expectRevert(bytes("Content should be eliminated"));
        utonoma.harvestLikes(id);

        // ─────────────────────────────────────────────────────────────
        // Step 5) User A sends 6 likes:
        //         -> likes = 6, dislikes = 6
        // ─────────────────────────────────────────────────────────────
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userA);
            utonoma.like(id);
        }

        // Con 6 likes y 6 dislikes:
        // - shouldContentBeEliminated(6, 6) should be false,
        //   so it will the first require.
        // - But in the second require:
        //   require(content.likes > content.dislikes, "Likes should be greater than dislikes");
        //   Fails (6 > 6 is false), so it will revert with this message.
        vm.prank(userB);
        vm.expectRevert(bytes("Likes should be greater than dislikes"));
        utonoma.harvestLikes(id);

        // ─────────────────────────────────────────────────────────────
        // Step 7) User A sends 1 more like:
        //         -> likes = 7, dislikes = 6
        // ─────────────────────────────────────────────────────────────
        vm.prank(userA);
        utonoma.like(id);

        // Optional sanity check: content should NOT be eliminated now.
        bool eliminatedAfter = utonoma.shouldContentBeEliminated(7, 6);
        assertFalse(eliminatedAfter, "Content should not be eliminated with 7 likes and 6 dislikes");

        // ─────────────────────────────────────────────────────────────
        // Step 8) User B harvests likes successfully:
        //   - shouldContentBeEliminated(...) == false
        //   - likes > dislikes  → 7 > 6
        //   - likes > dislikes + harvestedLikes → 7 > 6 + 0
        // ─────────────────────────────────────────────────────────────
        vm.prank(userB);
        utonoma.harvestLikes(id);

        Utonoma.Content memory contentAfterFirstHarvest = utonoma.getContentById(id);
        assertEq(
            contentAfterFirstHarvest.harvestedLikes,
            1,
            "harvestedLikes should be 1 after the first successful harvest"
        );

        // ─────────────────────────────────────────────────────────────
        // Step 9) User B tries to harvest again:
        //   - likes = 7, dislikes = 6, harvestedLikes = 1
        //   - Third require is:
        //        require(likes > dislikes + harvestedLikes, "There are no more likes to harvest");
        //     → 7 > 6 + 1  → 7 > 7  → false
        //   - It MUST revert with "There are no more likes to harvest"
        // ─────────────────────────────────────────────────────────────
        vm.prank(userB);
        vm.expectRevert(bytes("There are no more likes to harvest"));
        utonoma.harvestLikes(id);
    }
}
