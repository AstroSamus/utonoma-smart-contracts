const { expect } = require("chai")
const { ethers } = require("hardhat")

async function deployTimeFixture() {
  const Time = await ethers.getContractFactory("Time")
  const time = await Time.deploy()

  await time.waitForDeployment()

  return { time }
}

describe("Time - unit tests", function () {


  it("should record the correct start time at deployment", async function () {
    const { time } = await deployTimeFixture()

    const deployTx = time.deploymentTransaction()
    const receipt = await deployTx.wait()
    const block = await ethers.provider.getBlock(receipt.blockNumber)
    const start = await time.startTimeOfTheNetwork()

    // It should match the timestamp of the deployment block
    expect(start).to.equal(block.timestamp)
  })

  it("should keep a constant start time even if time moves forward", async function () {
    const { time } = await deployTimeFixture()

    const startInitial = await time.startTimeOfTheNetwork()
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60])
    await ethers.provider.send("evm_mine")
    const startAfter = await time.startTimeOfTheNetwork()

    // It must remain exactly the same (immutable)
    expect(startAfter).to.equal(startInitial)
  })
})
