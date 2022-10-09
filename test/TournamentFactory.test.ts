import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

describe("Tournament", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function coreDeployment() {
    // Contracts are deployed using the first signer/account by default
    const [owner, player1, player2, player3, player4, player5] = await ethers.getSigners();

    const BattleLogicHandler = await ethers.getContractFactory("BattleLogicHandler");
    const handler = await BattleLogicHandler.deploy();

    const TournamentFactory = await ethers.getContractFactory("TournamentFactory");
    const factory = await TournamentFactory.deploy(
      "Test Warrior",
      "WRR",
      ethers.utils.parseEther("1.0"),
      true,
      handler.address,
    );

    return { handler, factory, owner, player1, player2, player3, player4, player5 };
  }

  describe("Deployment", function () {
    it("Should correctly deploy the TournamentFactory", async function () {
      const { factory, owner } = await loadFixture(coreDeployment);

      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should correctly deploy a new Tournament", async function () {
      const { factory, owner } = await loadFixture(coreDeployment);

      const duration = 100;
      const timestampedDuration = Math.floor(Date.now() / 1000) + 60 * 60 * 24 * duration;
      const tx = await factory.newTournament(ethers.utils.parseEther("1.0"), timestampedDuration, 10);
      const events = (await tx.wait()).events;
      const validEvents = events?.filter(
        (event: any) => event.event === "NewTournamentCreated" && event.args && event.args[1] === duration,
      );
      console.log(validEvents);
      expect(validEvents?.length).equal(1);
    });
  });
});
