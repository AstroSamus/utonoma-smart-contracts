// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

/// @dev End-to-end test covering a full happy path scenario
contract UtonomaHappyPathTest is Test {
    Utonoma internal utonoma;

    // Actors
    address internal owner = address(this);
    address internal userA = address(0xA1);
    address internal userB = address(0xA2);
    address internal userC = address(0xA3);
    address internal userD = address(0xA4);
    address internal userE = address(0xA5);
    address internal userF = address(0xA6);
    address internal userG = address(0xA7);

    // Re-declare events to use vm.expectEmit
    event uploaded(address indexed contentCreator, uint256 index, uint256 contentType);
    event liked(uint256 indexed index, uint256 indexed contentType);
    event disliked(uint256 indexed index, uint256 indexed contentType);
    event harvested(uint256 indexed index, uint256 indexed contentType, uint256 amount);
    event deleted(
        address indexed owner,
        bytes32 content,
        bytes32 metadata,
        uint256 indexed index,
        uint8 indexed contentType
    );
    event replied(
        uint256 replyIndex,
        uint256 replyContentType,
        uint256 indexed replyingToIndex,
        uint256 indexed replyingToContentType
    );

    function setUp() public {
        // Initial supply = 5,000,000 * 10^18
        utonoma = new Utonoma("Nomax", "NOMX", 5_000_000 ether);
    }

    function testHappyPathFullScenario() public {
        uint256 initialTotalSupply = utonoma.totalSupply();

        // ─────────────────────────────────────────────
        // Precompute fee values used in the economic model
        // ─────────────────────────────────────────────
        uint256 feeMAU0 = utonoma.calculateFee(0); //fee for Monthly Active Users = 0
        uint256 feeMAU1 = utonoma.calculateFee(1); //fee for Monthly Active Users = 1
        uint256 feeMAU2 = utonoma.calculateFee(2);
        uint256 feeMAU3 = utonoma.calculateFee(3);

        uint256 totalFeeSum;          // Sum of all fees charged (before burning)
        uint256 totalRewardMinted;    // Total amount minted through harvestLikes

        // We will also check at the end that:
        // finalTotalSupply = initialTotalSupply - totalFeeSum/4 + totalRewardMinted

        // ─────────────────────────────────────────────
        // STEP 1: User A uploads content (no tokens, no strike fee)
        // ─────────────────────────────────────────────
        ContentStorage.ContentTypes baseContentType = ContentStorage.ContentTypes.shortVideos; // shortVideos
        bytes32 baseContentHash = keccak256("content-A");
        bytes32 baseMetadataHash = keccak256("metadata-A");

        // First content for this library, index is expected to be 0
        vm.expectEmit(true, false, false, true, address(utonoma));
        emit uploaded(userA, 0, uint256(baseContentType));

        vm.prank(userA);
        Utonoma.Identifier memory baseContentId =
            utonoma.upload(baseContentHash, baseMetadataHash, baseContentType);

        assertEq(baseContentId.index, 0, "Base content index should be 0");
        assertEq(uint256(baseContentId.contentType), uint256(baseContentType), "Base content type mismatch");

        // ─────────────────────────────────────────────
        // STEP 2: Owner transfers feeMAU0 tokens to User B
        // ─────────────────────────────────────────────
        vm.prank(owner);
        utonoma.transfer(userB, feeMAU0);

        // ─────────────────────────────────────────────
        // STEP 3: User B likes A's content once
        //   - Fee uses MAU = 0
        //   - Contract balance increases by 3/4 * feeMAU0
        //   - Total supply decreases by 1/4 * feeMAU0
        // ─────────────────────────────────────────────
        uint256 contractBalanceBeforeFees = utonoma.balanceOf(address(utonoma));

        vm.expectEmit(true, true, true, true, address(utonoma));
        emit liked(baseContentId.index, uint256(baseContentType));

        vm.prank(userB);
        utonoma.like(baseContentId);

        totalFeeSum += feeMAU0;

        // ─────────────────────────────────────────────
        // STEP 4: Owner transfers to User C enough tokens for:
        //   - 1 like with MAU = 1 (feeMAU1)
        //   - 4 likes with MAU = 2 (4 * feeMAU2)
        // ─────────────────────────────────────────────
        uint256 amountToC = feeMAU1 + feeMAU2 * 4;
        vm.prank(owner);
        utonoma.transfer(userC, amountToC);

        // ─────────────────────────────────────────────
        // STEP 5: User C likes the same content 5 times
        //   - 1st like sees MAU = 1 -> feeMAU1
        //   - Next 4 likes see MAU = 2 -> feeMAU2 each
        //   (We only accumulate total fees here; the aggregated
        //    economic checks will happen later.)
        // ─────────────────────────────────────────────
        // First like from C (MAU = 1)
        vm.expectEmit(true, true, true, true, address(utonoma));
        emit liked(baseContentId.index, uint256(baseContentType));

        vm.prank(userC);
        utonoma.like(baseContentId);
        totalFeeSum += feeMAU1;

        // Next 4 likes from C (MAU = 2)
        for (uint256 i = 0; i < 4; i++) {
            vm.expectEmit(true, true, true, true, address(utonoma));
            emit liked(baseContentId.index, uint256(baseContentType));

            vm.prank(userC);
            utonoma.like(baseContentId);
            totalFeeSum += feeMAU2;
        }

        // After these likes, we expect:
        // likes = 6 (1 from B, 5 from C), dislikes = 0, harvestedLikes = 0
        Utonoma.Content memory contentAfterLikes = utonoma.getContentById(baseContentId);
        assertEq(contentAfterLikes.likes, 6, "Content should have 6 likes before harvest");
        assertEq(contentAfterLikes.dislikes, 0, "Content should have 0 dislikes before harvest");
        assertEq(contentAfterLikes.harvestedLikes, 0, "Content should have 0 harvestedLikes before harvest");

        // Also MAU for current period should be 2 (two distinct users: B and C)
        assertEq(utonoma.currentPeriodMAU(), 2, "currentPeriodMAU should be 2 before harvest");

        // ─────────────────────────────────────────────
        // STEP 6: User A harvests the likes
        //   - likesToHarvest = likes - dislikes - harvestedLikes = 6
        //   - currentPeriodMAU() = 2 -> reward per like = calculateReward(2)
        //   - total reward = 6 * calculateReward(2)
        //   - User A balance increases by that reward
        //   - Total supply increases by the same amount
        //   - Event harvested is emitted
        // ─────────────────────────────────────────────
        uint256 rewardPerLike = utonoma.calculateReward(2);
        uint256 expectedReward = rewardPerLike * 6;

        uint256 balanceABeforeHarvest = utonoma.balanceOf(userA);

        vm.expectEmit(true, true, true, true, address(utonoma));
        emit harvested(baseContentId.index, uint256(baseContentType), expectedReward);

        vm.prank(userA);
        utonoma.harvestLikes(baseContentId);

        uint256 balanceAAfterHarvest = utonoma.balanceOf(userA);
        assertEq(
            balanceAAfterHarvest - balanceABeforeHarvest,
            expectedReward,
            "User A should receive the expected harvest reward"
        );

        totalRewardMinted += expectedReward;

        Utonoma.Content memory contentAfterHarvest = utonoma.getContentById(baseContentId);
        assertEq(contentAfterHarvest.harvestedLikes, 6, "All 6 likes should be marked as harvested");
        assertEq(contentAfterHarvest.likes, 6, "Number of likes should remain 6 after harvest");

        // ─────────────────────────────────────────────
        // STEP 7: Owner transfers to User D enough for:
        //   - 1 dislike with MAU = 2 -> feeMAU2
        //   - 14 dislikes with MAU = 3 -> 14 * feeMAU3
        // ─────────────────────────────────────────────
        uint256 amountToD = feeMAU2 + feeMAU3 * 14;
        vm.prank(owner);
        utonoma.transfer(userD, amountToD);

        // First dislike from D (MAU = 2)
        vm.expectEmit(true, true, true, true, address(utonoma));
        emit disliked(baseContentId.index, uint256(baseContentType));

        vm.prank(userD);
        utonoma.dislike(baseContentId);
        totalFeeSum += feeMAU2;

        // 14 additional dislikes from D (MAU = 3)
        for (uint256 i = 0; i < 14; i++) {
            vm.expectEmit(true, true, true, true, address(utonoma));
            emit disliked(baseContentId.index, uint256(baseContentType));

            vm.prank(userD);
            utonoma.dislike(baseContentId);
            totalFeeSum += feeMAU3;
        }

        Utonoma.Content memory contentAfterDislikes = utonoma.getContentById(baseContentId);
        assertEq(contentAfterDislikes.likes, 6, "Likes should remain 6 after dislikes");
        assertEq(contentAfterDislikes.dislikes, 15, "Content should have 15 dislikes after D's actions");

        // ─────────────────────────────────────────────
        // STEP 8: User E calls deletion() on A's content
        //   - User E does not need any tokens
        //   - Content should be deleted (zeroed)
        //   - User A gets one strike
        //   - Event deleted is emitted
        // ─────────────────────────────────────────────
        uint64 strikesBeforeDeletion = utonoma.getUserProfile(userA).strikes;
        Utonoma.Content memory contentBeforeDeletion = utonoma.getContentById(baseContentId);

        vm.expectEmit(true, false, true, true, address(utonoma));
        emit deleted(
            contentBeforeDeletion.contentOwner,
            contentBeforeDeletion.contentHash,
            contentBeforeDeletion.metadataHash,
            baseContentId.index,
            uint8(baseContentType)
        );

        vm.prank(userE);
        utonoma.deletion(baseContentId);

        Utonoma.Content memory contentAfterDeletion = utonoma.getContentById(baseContentId);
        assertEq(contentAfterDeletion.contentOwner, address(0), "Deleted content owner should be zero");
        assertEq(contentAfterDeletion.contentHash, bytes32(0), "Deleted content hash should be zero");
        assertEq(contentAfterDeletion.metadataHash, bytes32(0), "Deleted metadata hash should be zero");
        assertEq(contentAfterDeletion.likes, 0, "Deleted content likes should be zero");
        assertEq(contentAfterDeletion.dislikes, 0, "Deleted content dislikes should be zero");
        assertEq(contentAfterDeletion.harvestedLikes, 0, "Deleted content harvestedLikes should be zero");

        uint64 strikesAfterDeletion = utonoma.getUserProfile(userA).strikes;
        assertEq(strikesAfterDeletion, strikesBeforeDeletion + 1, "User A should receive one strike");

        // ─────────────────────────────────────────────
        // STEP 9: Owner calls withdraw()
        //   Contract balance should be:
        //   3/4 * (1*feeMAU0 + 1*feeMAU1 + 5*feeMAU2 + 14*feeMAU3)
        //   We accumulated totalFeeSum exactly that way, so:
        //   contractBalance = 3/4 * totalFeeSum
        //   After withdraw, contract balance is 0 and owner balance increases by that amount
        // ─────────────────────────────────────────────

        uint256 totalBurned =
            (feeMAU0 / 4) * 1 +
            (feeMAU1 / 4) * 1 +
            (feeMAU2 / 4) * 5 +
            (feeMAU3 / 4) * 14;

        // The gathered fees in the smart contract should be the total fees payed by the users
        // minus the burned fees, this is aproximately totalFeeSum * 3 / 4, but we compute it
        // total fee - total burned to exactly to avoid rounding errors in the test
        uint256 expectedContractBalance = totalFeeSum - totalBurned;

        uint256 contractBalanceBeforeWithdraw = utonoma.balanceOf(address(utonoma));

        assertEq(
            contractBalanceBeforeWithdraw - contractBalanceBeforeFees,
            expectedContractBalance,
            "Contract fee balance should match 3/4 of all fees"
        );

        uint256 ownerBalanceBeforeWithdraw = utonoma.balanceOf(owner);

        vm.prank(owner);
        utonoma.withdraw();

        uint256 ownerBalanceAfterWithdraw = utonoma.balanceOf(owner);
        uint256 contractBalanceAfterWithdraw = utonoma.balanceOf(address(utonoma));

        assertEq(
            ownerBalanceAfterWithdraw - ownerBalanceBeforeWithdraw,
            contractBalanceBeforeWithdraw,
            "Owner should receive the full contract balance on withdraw"
        );
        assertEq(contractBalanceAfterWithdraw, 0, "Contract balance should be zero after withdraw");

        // ─────────────────────────────────────────────
        // STEP 10: User F uploads content to the same library
        // ─────────────────────────────────────────────
        bytes32 fContentHash = keccak256("content-F");
        bytes32 fMetadataHash = keccak256("metadata-F");

        uint256 libraryLengthBeforeF = utonoma.getContentLibraryLength(baseContentType);

        vm.expectEmit(true, false, false, true, address(utonoma));
        emit uploaded(userF, libraryLengthBeforeF, uint256(baseContentType));

        vm.prank(userF);
        Utonoma.Identifier memory fId =
            utonoma.upload(fContentHash, fMetadataHash, baseContentType);

        assertEq(fId.index, libraryLengthBeforeF, "F's content index should match library length before upload");

        // ─────────────────────────────────────────────
        // STEP 11: User G uploads content to the same library
        // ─────────────────────────────────────────────
        bytes32 gContentHash = keccak256("content-G");
        bytes32 gMetadataHash = keccak256("metadata-G");

        uint256 libraryLengthBeforeG = utonoma.getContentLibraryLength(baseContentType);

        vm.expectEmit(true, false, false, true, address(utonoma));
        emit uploaded(userG, libraryLengthBeforeG, uint256(baseContentType));

        vm.prank(userG);
        Utonoma.Identifier memory gId =
            utonoma.upload(gContentHash, gMetadataHash, baseContentType);

        assertEq(gId.index, libraryLengthBeforeG, "G's content index should match library length before upload");

        // ─────────────────────────────────────────────
        // STEP 12: User F uses its content as reply to G's content
        //   - No Nomax required
        //   - Event replied is emitted
        //   - Relationship is stored in ContentStorage
        // ─────────────────────────────────────────────
        vm.expectEmit(false, false, true, true, address(utonoma));
        emit replied(
            fId.index,
            uint256(fId.contentType),
            gId.index,
            uint256(gId.contentType)
        );

        vm.prank(userF);
        utonoma.reply(fId, gId);

        // Check that G's content has F in its replies
        Utonoma.Identifier[] memory repliesToG = utonoma.getRepliesToThisContent(gId);
        bool foundF = false;
        for (uint256 i = 0; i < repliesToG.length; i++) {
            if (repliesToG[i].index == fId.index && repliesToG[i].contentType == fId.contentType) {
                foundF = true;
                break;
            }
        }
        assertTrue(foundF, "F's content should appear in the replies list of G's content");

        // ─────────────────────────────────────────────
        // STEP 13: User G voluntarily deletes its content
        //   - voluntarilyDelete does NOT emit any event in the current implementation,
        //     so we only verify that the content is cleared.
        // ─────────────────────────────────────────────
        vm.prank(userG);
        utonoma.voluntarilyDelete(gId);

        Utonoma.Content memory gAfterDelete = utonoma.getContentById(gId);
        assertEq(gAfterDelete.contentOwner, address(0), "Voluntary delete: owner should be zero");
        assertEq(gAfterDelete.contentHash, bytes32(0), "Voluntary delete: contentHash should be zero");
        assertEq(gAfterDelete.metadataHash, bytes32(0), "Voluntary delete: metadataHash should be zero");
        assertEq(gAfterDelete.likes, 0, "Voluntary delete: likes should be zero");
        assertEq(gAfterDelete.dislikes, 0, "Voluntary delete: dislikes should be zero");
        assertEq(gAfterDelete.harvestedLikes, 0, "Voluntary delete: harvestedLikes should be zero");

        // ─────────────────────────────────────────────
        // STEP 14: Owner pauses the contract
        //   - Main functions protected by whenNotPaused
        //     must revert with "Pausable: paused"
        // ─────────────────────────────────────────────
        vm.prank(owner);
        utonoma.pause();
        assertTrue(utonoma.paused(), "Contract should be paused");

        // upload()
        vm.prank(userA);
        vm.expectRevert("EnforcedPause()");
        utonoma.upload(keccak256("new-content"), keccak256("new-meta"), baseContentType);

        // like()
        vm.prank(userB);
        vm.expectRevert("EnforcedPause()");
        utonoma.like(fId);

        // dislike()
        vm.prank(userC);
        vm.expectRevert("EnforcedPause()");
        utonoma.dislike(fId);

        // harvestLikes()
        vm.prank(userA);
        vm.expectRevert("EnforcedPause()");
        utonoma.harvestLikes(fId);

        // deletion()
        vm.prank(userE);
        vm.expectRevert("EnforcedPause()");
        utonoma.deletion(fId);

        // reply()
        vm.prank(userF);
        vm.expectRevert("EnforcedPause()");
        utonoma.reply(fId, gId);

        // createUser()
        vm.prank(userA);
        vm.expectRevert("EnforcedPause()");
        utonoma.createUser(
            bytes15(0x757365725f6e616d655f3100000000), // "user_name_1"
            bytes32(0)
        );

        // updateUserMetadataHash()
        vm.prank(userA);
        vm.expectRevert("EnforcedPause()");
        utonoma.updateUserMetadataHash(bytes32(uint256(0x1234)));

        // withdraw()
        vm.prank(owner);
        vm.expectRevert("EnforcedPause()");
        utonoma.withdraw();

        // ─────────────────────────────────────────────
        // Final economic consistency check:
        // totalSupply should equal:
        // initialTotalSupply - totalBurned + totalRewardMinted
        // ─────────────────────────────────────────────

        uint256 expectedFinalTotalSupply =
            initialTotalSupply - totalBurned + totalRewardMinted;

        assertEq(
            utonoma.totalSupply(),
            expectedFinalTotalSupply,
            "Final totalSupply should match initial - burnedFees + mintedRewards"
        );
    }
}
