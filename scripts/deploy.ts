import { types } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";

task("deploy", "Deploy the game contracts")
  .addOptionalParam("noverify", "Skip verification", true, types.boolean)
  .setAction(async (taskArgs: TaskArguments, hre: HardhatRuntimeEnvironment) => {
    const noverify = taskArgs.noverify;

    const BattleLogicHandler = await hre.ethers.getContractFactory("BattleLogicHandler");
    const handler = await BattleLogicHandler.deploy();
    await handler.deployed();
    console.log(`BattleLogicHandler deployed to ${handler.address}`);

    if (!noverify) {
      await hre.run("verify:verify", {
        address: handler.address,
        constructorArguments: [],
      });
    }

    const TournamentFactory = await hre.ethers.getContractFactory("TournamentFactory");
    const factory = await TournamentFactory.deploy(
      "Test Warrior",
      "WRR",
      hre.ethers.utils.parseEther("1.0"),
      true,
      handler.address,
    );
    await factory.deployed();
    console.log(`TournamentFactory deployed to ${factory.address}`);

    if (!noverify) {
      await hre.run("verify:verify", {
        address: factory.address,
        constructorArguments: ["Test Warrior", "WRR", hre.ethers.utils.parseEther("1.0"), true, handler.address],
      });
    }
  });
