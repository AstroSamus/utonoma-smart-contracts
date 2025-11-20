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

  it("should record the correct start time at deployment", async function () {
    const { utonoma } = await deployUtonomaFixture()

    const deployTx = utonoma.deploymentTransaction()
    const receipt = await deployTx.wait()
    const block = await ethers.provider.getBlock(receipt.blockNumber)
    const start = await utonoma.startTimeOfTheNetwork()

    // It should match the timestamp of the deployment block
    expect(start).to.equal(block.timestamp)
  })

  it("should keep a constant start time even if time moves forward", async function () {
    const { utonoma } = await deployUtonomaFixture()
    const startInitial = await utonoma.startTimeOfTheNetwork()

    // Move forward 1 week in Hardhat time
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60])
    await ethers.provider.send("evm_mine")
    // Read again
    const startAfter = await utonoma.startTimeOfTheNetwork()
    // It must remain exactly the same (immutable)
    
    expect(startAfter).to.equal(startInitial)
  })
})