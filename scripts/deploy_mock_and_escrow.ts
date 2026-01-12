import { ethers } from "hardhat";
import { config as dotenvConfig } from "dotenv";
dotenvConfig();

async function main() {
  const verifier = process.env.VERIFIER_ADDRESS!;
  if (!verifier) throw new Error("VERIFIER_ADDRESS missing");

  const Mock = await ethers.getContractFactory("MockERC20");
  const mock = await Mock.deploy();
  await mock.waitForDeployment();
  const tokenAddr = await mock.getAddress();

  const TipEscrow = await ethers.getContractFactory("TipEscrow");
  const escrow = await TipEscrow.deploy(tokenAddr, verifier);
  await escrow.waitForDeployment();

  console.log("Mock token:", tokenAddr);
  console.log("TipEscrow:", await escrow.getAddress());
  console.log("Verifier:", verifier);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
