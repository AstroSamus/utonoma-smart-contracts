// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";

contract UtonomaHandler is Test {
    Utonoma public utonoma;

    // Single content that all fuzzed users will like/dislike
    Utonoma.Identifier public baseContentId;

    // Actors that will be chosen pseudo-randomly
    address[] public actors;

    // Time model
    uint256 public immutable startTimeOfNetwork;
    uint256 public constant PERIOD = 30 days;

    // For invariants: total number of like/dislike calls that
    // excecuted without reverting.
    uint256 public totalInteractions;

    constructor(Utonoma _utonoma) {
        utonoma = _utonoma;
        startTimeOfNetwork = _utonoma.startTimeOfTheNetwork();
    }

    ///@notice This methods will be called from the invariants contract to end configuration
    function setBaseContentId(Utonoma.Identifier memory id) external {
        baseContentId = id;
    }

    ///@notice This methods will be called from the invariants contract to end configuration
    function setActors(address[] memory _actors) external {
        // delete the actors array, it will be repopulated every time the invariant setup is called
        // this will happen multiple times but the Handler is deployed only once
        delete actors;
        for (uint256 i = 0; i < _actors.length; i++) {
            actors.push(_actors[i]);
        }
    }

    // -------------------------------------------------------------------------
    // Actions fuzz: like / dislike
    // -------------------------------------------------------------------------

    /// @dev Simulate a lke from a random actor at a random period
    /// @notice Foundry will fuzz actorSeed and monthBump.
    /// @notice Later in the invariants we will send tokens to actors to pay the fees for voting
    /// @param actorSeed Seed to pick the actor pseudo-randomly
    /// @param monthBump Number of months to advance the time
    function likeAs(uint256 actorSeed, uint256 monthBump) public {
        if (actors.length == 0) return;
        // validate content type is valid as a handler should never revert as the 
        // invariants test may send false possitives
        if (uint(baseContentId.contentType) > utonoma.getMaxContentTypes()) return;

        address actor = actors[actorSeed % actors.length];

        _warpForward(monthBump);

        vm.prank(actor);
        //If the like reverts we will not count as a successful interaction.
        try utonoma.like(baseContentId) {
            totalInteractions++;
        } catch {
            // ignore reverts: invariant should not fail because of that
        }
    }

    /// @dev Just as likeAs, but for dislikes
    function dislikeAs(uint256 actorSeed, uint256 monthBump) public {
        if (actors.length == 0) return;
        // validate content type is valid as a handler should never revert as the 
        // invariants test may send false possitives
        if (uint256(baseContentId.contentType) > utonoma.getMaxContentTypes()) return;

        address actor = actors[actorSeed % actors.length];

        _warpForward(monthBump);

        vm.prank(actor);
        try utonoma.dislike(baseContentId) {
            totalInteractions++;
        } catch {
            // ignore reverts
        }
    }

    // -------------------------------------------------------------------------
    // Time helpers
    // -------------------------------------------------------------------------

    /// @dev Calculates a new time and warps there.
    /// @notice Only increases time, never decreases it.
    /// @param monthBump Controls how many "30-day periods" we jump forward.
    function _warpForward(uint256 monthBump) internal {
        // How many 30 days periods have elapsed since the network started
        uint256 currentElapsed = (block.timestamp - startTimeOfNetwork) / PERIOD;
        uint256 extraMonths = monthBump % 12; // limit up to 12 months only

        // How many periods will have elapsed after the warp
        uint256 newElapsed = currentElapsed + extraMonths;
        uint256 newTimestamp = startTimeOfNetwork + newElapsed * PERIOD + 1 days;

        // Only warp time if the new time is in the future
        if (newTimestamp > block.timestamp) {
            vm.warp(newTimestamp);
        }
    }
}
