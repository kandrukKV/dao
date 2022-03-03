import { ethers } from "hardhat";

async function main() {
  const DAO = await ethers.getContractFactory("DAO");
  // без реального деплоя
  const greeter = await DAO.deploy();

  await greeter.deployed();

  console.log("Greeter deployed to:", greeter.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
