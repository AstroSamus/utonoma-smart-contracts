// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

contract Time {
    uint256 internal immutable _startTimeOfTheNetwork;

    constructor() {
        _startTimeOfTheNetwork = block.timestamp;
    }

    /// @notice gets the time in wich the contract was deployed
    function startTimeOfTheNetwork() public view returns (uint256) {
        return _startTimeOfTheNetwork;
    }
}