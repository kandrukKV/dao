import { expect } from "chai";
import { ethers } from "hardhat";

describe("DAO", function () {
  let daoContract: any;
  let tokenContract: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;

  before(async function name() {
    const dao = await ethers.getContractFactory("DAO");
    const token = await ethers.getContractFactory("VRNToken");
    [owner, user1, user2, user3] = await ethers.getSigners();

    tokenContract = await token.deploy();
    await tokenContract.deployed();

    daoContract = await dao.deploy(
      tokenContract.address,
      owner.address,
      30, // %
      300 // 5 sec
    );
    await daoContract.deployed();
    await tokenContract.setMintRole(daoContract.address);
  });

  it("Mint tokens", async function () {
    await tokenContract.mint(user1.address, "1000000000000000000000");
    await tokenContract.mint(user2.address, "500000000000000000000");

    expect(await tokenContract.balanceOf(user1.address)).to.equal(
      "1000000000000000000000"
    );

    expect(await tokenContract.balanceOf(user2.address)).to.equal(
      "500000000000000000000"
    );
  });
  it("Create proposal", async function () {
    const callData = tokenContract.interface.encodeFunctionData("mint", [
      user3.address,
      "333000000000000000000",
    ]);

    await expect(
      daoContract
        .connect(user1)
        .addProposal(
          callData,
          tokenContract.address,
          "Mint 333 tokens to user3"
        )
    ).to.be.revertedWith("Only chairPerson can make it");

    await daoContract.addProposal(
      callData,
      tokenContract.address,
      "Mint 333 tokens to user3"
    );

    expect(await daoContract.getProposalsCount()).to.equal(1);
  });
  it("Zero Balance Voting", async function () {
    const balance = await daoContract.getUserBalance(user1.address);

    expect(balance).to.equal(0);

    await expect(daoContract.connect(user1).vote(1, true)).to.be.revertedWith(
      "Only tokenholders"
    );
  });
  it("Top Up balance", async function () {
    await tokenContract
      .connect(user1)
      .approve(daoContract.address, "250000000000000000000");
    await daoContract.connect(user1).topUpBalance("250000000000000000000");
    expect(await daoContract.getUserBalance(user1.address)).to.equal(
      "250000000000000000000"
    );

    await tokenContract
      .connect(user2)
      .approve(daoContract.address, "150000000000000000000");
    await daoContract.connect(user2).topUpBalance("150000000000000000000");
    expect(await daoContract.getUserBalance(user2.address)).to.equal(
      "150000000000000000000"
    );
  });
  it("Vote", async function () {
    await daoContract.connect(user1).vote(1, true);
    await daoContract.connect(user2).vote(1, false);

    await expect(daoContract.connect(user1).vote(2, true)).to.be.revertedWith(
      "No proposal"
    );

    await expect(daoContract.connect(user1).vote(1, true)).to.be.revertedWith(
      "Vote is already taken into account"
    );

    const proposal = await daoContract.getProposal(1);

    expect(proposal[1]).to.equal("150000000000000000000");
    expect(proposal[2]).to.equal("250000000000000000000");
  });
  it("Requce balance if amount is wrong", async function () {
    await expect(
      daoContract.connect(user1).reduceBalance("350000000000000000000")
    ).to.be.revertedWith("The amount more then balance");
  });
  it("Requce balance if you are voting", async function () {
    // await expect(
    //   daoContract.connect(user1).reduceBalance("150000000000000000000")
    // ).to.be.revertedWith("Wait for the end of voting");
  });
  it("Finish voting", async function () {
    // await expect(daoContract.connect(user1).finishProposal(1));
  });
});
