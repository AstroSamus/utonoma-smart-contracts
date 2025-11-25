// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../contracts/Utonoma.sol";
import "forge-std/Test.sol";

/// @dev Harness to expose _owner as there is no public getter for it.
contract UtonomaHarness is Utonoma {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) Utonoma(name_, symbol_, initialSupply) {}

    function owner_() external view returns (address) {
        return _owner;
    }
}

contract UtonomaTest is Test {
    UtonomaHarness internal utonoma;
    address internal deployer;

    string constant NAME = "testNomax";
    string constant SYMBOL = "testNOMX";
    uint256 constant INITIAL_SUPPLY = 5_000_000 ether;

    function setUp() public {
        deployer = address(0xD1);

        vm.prank(deployer);
        utonoma = new UtonomaHarness(NAME, SYMBOL, INITIAL_SUPPLY);
    }

    function testDeploymentAddressIsValid() public view {
        // Equivalente a "expect(utonoma.target).to.be.properAddress"
        assertTrue(address(utonoma) != address(0), "Utonoma address should not be zero");
    }

    function testTokenNameAndSymbol() public view {
        assertEq(utonoma.name(), NAME, "Token name should match constructor argument");
        assertEq(utonoma.symbol(), SYMBOL, "Token symbol should match constructor argument");
    }

    function testInitialSupplyMintedToDeployer() public view {
        uint256 totalSupply = utonoma.totalSupply();
        uint256 deployerBalance = utonoma.balanceOf(deployer);

        assertEq(totalSupply, INITIAL_SUPPLY, "Total supply should equal initial supply");
        assertEq(
            deployerBalance,
            INITIAL_SUPPLY,
            "Deployer balance should equal initial supply"
        );
    }

    function testOwnerIsDeployer() public view {
        assertEq(
            utonoma.owner_(),
            deployer,
            "Internal _owner should be the deployer address"
        );
    }

    function testStartsUnpaused() public view {
        bool isPaused = utonoma.paused();
        assertFalse(isPaused, "Contract should start unpaused");
    }

    function testContractStartsWithZeroBalance() public view {
        uint256 contractBalance = utonoma.balanceOf(address(utonoma));
        assertEq(
            contractBalance,
            0,
            "Contract address should start with zero token balance"
        );
    }
}
