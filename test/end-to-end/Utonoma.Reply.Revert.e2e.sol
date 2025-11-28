// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaReplyRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA;
    address private userB;

    // We'll use a single content type for simplicity
    ContentStorage.ContentTypes private constant BASE_CONTENT_TYPE =
        ContentStorage.ContentTypes.videos;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        uint256 INITIAL_SUPPLY = 5_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);
    }

    function testReply_RevertIfNotOwnerOfReplyContent() public {
        // 1) User A uploads a content
        vm.prank(userA);
        bytes32 contentHashA = keccak256("content-A");
        bytes32 metadataHashA = keccak256("metadata-A");
        utonoma.upload(contentHashA, metadataHashA, BASE_CONTENT_TYPE);

        // 2) User B uploads another content (same content type)
        vm.prank(userB);
        bytes32 contentHashB = keccak256("content-B");
        bytes32 metadataHashB = keccak256("metadata-B");
        utonoma.upload(contentHashB, metadataHashB, BASE_CONTENT_TYPE);

        // Assuming sequential indexing in the same content type:
        // - User A's content → index 0
        // - User B's content → index 1
        ContentStorage.Identifier memory idA =
            ContentStorage.Identifier({index: 0, contentType: BASE_CONTENT_TYPE});
        ContentStorage.Identifier memory idB =
            ContentStorage.Identifier({index: 1, contentType: BASE_CONTENT_TYPE});

        // 3) User A tries to use B's content (idB) as reply to their own (idA)
        vm.prank(userA);
        vm.expectRevert(
            bytes("Only the owner of the content can use it as a reply")
        );
        utonoma.reply(idB, idA);

        // Optional sanity check: both contents still exist and owners are correct
        Utonoma.Content memory contentA = utonoma.getContentById(idA);
        Utonoma.Content memory contentB = utonoma.getContentById(idB);

        assertEq(contentA.contentOwner, userA, "Content A owner must be userA");
        assertEq(contentB.contentOwner, userB, "Content B owner must be userB");
    }
}
