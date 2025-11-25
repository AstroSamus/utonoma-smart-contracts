// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaVoluntarilyDeleteRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA;
    address private userB;

    ContentStorage.ContentTypes private constant BASE_CONTENT_TYPE =
        ContentStorage.ContentTypes.videos;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // Deploy contract with a high initial supply
        uint256 INITIAL_SUPPLY = 1_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);

        // Transfer no tokens to users (not needed for this test)
    }

    function testVoluntarilyDelete_RevertIfNotOwner() public {
        // 1) User A uploads content
        vm.prank(userA);
        bytes32 contentHash = keccak256("A-content");
        bytes32 metadataHash = keccak256("A-metadata");

        utonoma.upload(contentHash, metadataHash, BASE_CONTENT_TYPE);

        // The uploaded content has index 0 in this content type
        ContentStorage.Identifier memory id =
            ContentStorage.Identifier({index: 0, contentType: BASE_CONTENT_TYPE});

        // 2) User B tries to delete content owned by A → REVERTS
        vm.prank(userB);
        vm.expectRevert(
            bytes("Only the content owner can voluntarily delete it")
        );
        utonoma.voluntarilyDelete(id);

        // Optional: check content still exists
        Utonoma.Content memory content = utonoma.getContentById(id);
        assertEq(
            content.contentOwner,
            userA,
            "Content must remain owned by user A after failed delete"
        );
    }
}
