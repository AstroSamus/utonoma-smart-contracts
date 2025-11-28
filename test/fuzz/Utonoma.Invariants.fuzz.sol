// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import {Utonoma} from "../../contracts/Utonoma.sol";
import {ContentStorage} from "../../contracts/ContentStorage.sol";
import {UtonomaHandler} from "./Utonoma.Handler.fuzz.sol";

contract UtonomaInvariants is StdInvariant, Test {
    Utonoma public utonoma;
    UtonomaHandler public handler;

    address internal owner;
    address[] internal actors;

    uint256[] internal lastHistoricSnapshot;

    function setUp() public {
        owner = address(this);

        uint256 INITIAL_SUPPLY = 5_000_000 * 1e18;
        utonoma = new Utonoma("testNomax", "testNOMX", INITIAL_SUPPLY);

        uint256 numActors = 5;
        actors = new address[](numActors);
        for (uint256 i = 0; i < numActors; i++) {
            actors[i] = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
            // Give each actor some tokens to pay for likes/dislikes
            utonoma.transfer(actors[i], 1_000_000 * 1e18);
        }

        // Create a base content to be liked/disliked
        address contentCreator = actors[0];
        vm.prank(contentCreator);
        bytes32 contentHash = keccak256("base-content");
        bytes32 metadataHash = keccak256("base-metadata");
        ContentStorage.ContentTypes contentType = ContentStorage.ContentTypes.videos;

        ContentStorage.Identifier memory id = utonoma.upload(
            contentHash,
            metadataHash,
            contentType
        );

        // Deploy and configure the handler
        handler = new UtonomaHandler(utonoma);
        handler.setBaseContentId(id);
        handler.setActors(actors);

        // Register the handler contract as a target for invariants testing
        targetContract(address(handler));

        // Snapshot of the historic MAU data at the beginning
        _snapshotHistoric();
    }


    /// @dev Tests the invariants for the currentPeriodMAU method
    function invariantCurrentPeriodMAU() public view {
        uint256[] memory history = utonoma.historicMAUData();
        uint256 current = utonoma.currentPeriodMAU();

        if (history.length == 0) {
            assertEq(current, 0, "currentPeriodMAU must be 0 when the network just started");
        } else if (history.length == 1) {
            assertEq(
                current,
                history[0],
                "On the first period of the network the currentPeriodMAU should be the count of the only period"
            );
        } else {
            assertEq(
                current,
                history[history.length - 2],
                "With >= 2 periods, currentPeriodMAU must equal the previous period"
            );
        }
    }

    /// @dev Tests the invariants of the historicMAUData.
    function invariantHistoricMAUData() public {
        uint256[] memory history = utonoma.historicMAUData();
        uint256 sum; // sum of all historic MAU values
        for (uint256 i = 0; i < history.length; i++) {
            sum += history[i];
        }

        uint256 totalInteractions = handler.totalInteractions();

        // Compare the snapshot of the previous run with the current data
        assertGe(
            history.length,
            lastHistoricSnapshot.length,
            "Historic MAU data array can only grow or remain the same and never shrink"
        );

        for (uint256 i = 0; i < lastHistoricSnapshot.length; i++) {
            assertGe(
                history[i],
                lastHistoricSnapshot[i],
                "Count of the current period MAU can only grow or remain the same and never decrease"
            );
        }

        assertLe(
            sum,
            totalInteractions,
            "Total sum of all the MAU data cannot exceed the total number of interactions"
        );

        // Update the snapshot for the next invariant check
        _snapshotHistoric();
    }

    // -------------------------------------------------------------------------
    // Helpers internos
    // -------------------------------------------------------------------------

    function _snapshotHistoric() internal {
        uint256[] memory current = utonoma.historicMAUData();
        delete lastHistoricSnapshot;
        for (uint256 i = 0; i < current.length; i++) {
            lastHistoricSnapshot.push(current[i]);
        }
    }
}
