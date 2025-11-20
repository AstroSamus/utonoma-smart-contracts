const { expect } = require("chai")
const { ethers } = require("hardhat")

async function deployUtonomaFixture() {
  const NAME = "testNomax"
  const SYMBOL = "testNOMX"
  const INITIAL_SUPPLY = ethers.parseUnits("5000000", 18) // 5 millones con 18 decimales

  const [deployer, ...users] = await ethers.getSigners()
  const Utonoma = await ethers.getContractFactory("Utonoma")
  const utonoma = await Utonoma.deploy(NAME, SYMBOL, INITIAL_SUPPLY)
  await utonoma.waitForDeployment()

  return {
    utonoma,
    deployer,
    users,
    NAME,
    SYMBOL,
    INITIAL_SUPPLY
  }
}

describe("Utonoma - End to End | Constructor & Basic Properties", function () {

  it("should deploy the Utonoma contract correctly", async function () {
    const { utonoma } = await deployUtonomaFixture()
    expect(utonoma.target).to.be.properAddress
  })

  it("should set the correct token name and symbol", async function () {
    const { utonoma, NAME, SYMBOL } = await deployUtonomaFixture()
    expect(await utonoma.name()).to.equal(NAME)
    expect(await utonoma.symbol()).to.equal(SYMBOL)
  })

  it("should mint the initial supply to the deployer", async function () {
    const { utonoma, deployer, INITIAL_SUPPLY } = await deployUtonomaFixture()

    const deployerBalance = await utonoma.balanceOf(deployer.address)
    expect(deployerBalance).to.equal(INITIAL_SUPPLY)
  })

  it("should start in an unpaused state", async function () {
    const { utonoma } = await deployUtonomaFixture()
    expect(await utonoma.paused()).to.equal(false)
  })

  it("should start with zero tokens in the contract itself", async function () {
    const { utonoma } = await deployUtonomaFixture()
    const balanceContract = await utonoma.balanceOf(utonoma.target)
    expect(balanceContract).to.equal(0)
  })
})