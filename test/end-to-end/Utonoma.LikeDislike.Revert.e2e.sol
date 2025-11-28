// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";

contract UtonomaLikeDislikeRevertTest is Test {
    Utonoma private utonoma;

    address private owner;
    address private userA;
    address private userB;

    function setUp() public {
        owner = address(this);
        userA = makeAddr("UserA");
        userB = makeAddr("UserB");

        // Deploy with large initial supply to owner
        utonoma = new Utonoma("testNomax", "testNOMX", 5_000_000 * 1e18);

        // Owner uploads a content (no fee because owner has 0 strikes)
        vm.prank(owner);
        bytes32 hash = keccak256("content");
        bytes32 meta = keccak256("metadata");
        utonoma.upload(hash, meta, ContentStorage.ContentTypes.videos);
    }

    function testLike_Revert_InsufficientBalance() public {
        // Content to like is always at index 0
        ContentStorage.Identifier memory id = ContentStorage.Identifier(0, ContentStorage.ContentTypes.videos);

        // User A has 0 tokens
        vm.prank(userA);
        vm.expectRevert(bytes("Balance is not enough to pay the fee"));
        utonoma.like(id);
    }

    function testDislike_Revert_InsufficientBalance() public {
        ContentStorage.Identifier memory id = ContentStorage.Identifier(0, ContentStorage.ContentTypes.videos);

        // User B has 0 tokens
        vm.prank(userB);
        vm.expectRevert(bytes("Balance is not enough to pay the fee"));
        utonoma.dislike(id);
    }
}