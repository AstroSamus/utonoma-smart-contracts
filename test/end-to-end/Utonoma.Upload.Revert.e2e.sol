// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaUploadRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA;
    address private userB;

    function setUp() public {
        // In Foundry, the test contract itself is the deployer (owner)
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // Deploy Utonoma with a large initial supply for the owner
        uint256 initialSupply = 5_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", initialSupply);

        // Owner transfers 100,000 NOMX to User B so they can pay dislike fees
        uint256 amountToUserB = 100_000 * 1e18;
        utonoma.transfer(userB, amountToUserB);
    }

    function testUpload_RevertWhen_UserHasStrikeAndNoBalanceToPayFee() public {
        // ───────────────────────────────────────────
        // 1) User A uploads a content with no strikes
        // ───────────────────────────────────────────
        ContentStorage.ContentTypes baseContentType = ContentStorage.ContentTypes.videos;

        bytes32 contentHash1 = keccak256(abi.encodePacked("content-1"));
        bytes32 metadataHash1 = keccak256(abi.encodePacked("metadata-1"));

        vm.prank(userA);
        Utonoma.Identifier memory contentId = utonoma.upload(
            contentHash1,
            metadataHash1,
            baseContentType
        );

        // ───────────────────────────────────────────
        // 2) User B dislikes A's content 6 times
        //    (0 likes, 6 dislikes => eligible for deletion)
        // ───────────────────────────────────────────
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(userB);
            utonoma.dislike(contentId);
        }

        // ───────────────────────────────────────────
        // 3) User B deletes A's content
        //    This adds 1 strike to User A
        // ───────────────────────────────────────────
        vm.prank(userB);
        utonoma.deletion(contentId);

        // (Optional sanity check: User A has at least 1 strike now)
        Utonoma.UserProfile memory profile = utonoma.getUserProfile(userA);
        assertEq(profile.strikes, 1, "User A should have one strike after deletion");

        // ───────────────────────────────────────────
        // 4) User A tries to upload again with 1 strike
        //    and zero NOMX balance => must revert on fee collection
        // ───────────────────────────────────────────
        bytes32 contentHash2 = keccak256(abi.encodePacked("content-2"));
        bytes32 metadataHash2 = keccak256(abi.encodePacked("metadata-2"));

        vm.prank(userA);
        vm.expectRevert(bytes("Balance is not enough to pay the fee"));
        utonoma.upload(contentHash2, metadataHash2, baseContentType);
    }
}
