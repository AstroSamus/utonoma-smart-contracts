const { expect } = require("chai")
const { ethers } = require("hardhat")

async function deployUtonomaFixture() {
  const name = "testNomax"
  const symbol = "testNOMX"
  const initialSupply = ethers.utils.parseUnits("5000000", 18) // 5 millones con 18 decimales

  const [deployer, ...otherAccounts] = await ethers.getSigners()
  const Utonoma = await ethers.getContractFactory("Utonoma")
  const utonoma = await Utonoma.deploy(name, symbol, initialSupply)
  await utonoma.deployed()

  return {
    utonoma,
    deployer,
    users,
    NAME,
    SYMBOL,
    INITIAL_SUPPLY
  }
}
