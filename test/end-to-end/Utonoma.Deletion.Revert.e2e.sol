// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaDeletionRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA; // will try to delete and also vote
    address private userB; // content creator

    // We'll always operate on the first content in this content type
    ContentStorage.ContentTypes private constant BASE_CONTENT_TYPE = ContentStorage.ContentTypes.videos;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // 1) Owner deploys the contract and gets the full initial supply
        uint256 INITIAL_SUPPLY = 5_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);

        // Owner transfers 3,000,000 NOMX to User A (more than enough to pay all fees)
        uint256 amountToUserA = 3_000_000 * 1e18;
        utonoma.transfer(userA, amountToUserA);

        // 2) User B uploads a content
        vm.prank(userB);
        bytes32 contentHash = keccak256("content-hash");
        bytes32 metadataHash = keccak256("metadata-hash");
        utonoma.upload(contentHash, metadataHash, BASE_CONTENT_TYPE);
    }

    function testDeletion_RevertsForQuorumAndVoteRatio() public {
        // We'll point to the first content in the selected content library (index 0)
        ContentStorage.Identifier memory id =
            ContentStorage.Identifier({index: 0, contentType: BASE_CONTENT_TYPE});

        // ─────────────────────────────────────────────────────────────
        // 3) User A tries to delete the content immediately:
        //    - likes = 0, dislikes = 0
        //    - shouldContentBeEliminated(0, 0) reverts with
        //      "Minimum quorum not reached"
        // ─────────────────────────────────────────────────────────────
        vm.prank(userA);
        vm.expectRevert(bytes("Minimum quorum not reached"));
        utonoma.deletion(id);

        // ─────────────────────────────────────────────────────────────
        // 4) User A sends 50 likes and 50 dislikes to B's content
        //    Total votes = 100 (>= minimum quorum).
        //    Dislike ratio is exactly 0.5, so content
        //    should NOT be eliminated.
        // ─────────────────────────────────────────────────────────────

        // 50 likes
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(userA);
            utonoma.like(id);
        }

        // 50 dislikes
        for (uint256 i = 0; i < 50; i++) {
            vm.prank(userA);
            utonoma.dislike(id);
        }

        // Optional sanity check: content still exists
        Utonoma.Content memory contentAfterVotes = utonoma.getContentById(id);
        assertEq(
            contentAfterVotes.likes,
            50,
            "Content should have 50 likes after voting"
        );
        assertEq(
            contentAfterVotes.dislikes,
            50,
            "Content should have 50 dislikes after voting"
        );

        // ─────────────────────────────────────────────────────────────
        // 5) User A tries to delete again:
        //    - Total votes >= quorum → no revert from Utils
        //    - shouldContentBeEliminated(...) == false (dislike ratio == 0.5)
        //    - So the `require(shouldContentBeEliminated(...), "Not enough negative votes to delete")`
        //      fails and MUST revert with:
        //        "Not enought negative votes to delete"
        // ─────────────────────────────────────────────────────────────
        vm.prank(userA);
        vm.expectRevert(bytes("Not enough negative votes to delete"));
        utonoma.deletion(id);

        // Content should still exist after failed deletion
        Utonoma.Content memory contentAfterFailedDeletion = utonoma.getContentById(id);
        assertEq(
            contentAfterFailedDeletion.contentOwner,
            userB,
            "Content owner should still be user B after failed deletion"
        );
    }
}
