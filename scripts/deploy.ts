import { ethers } from "hardhat";

async function main() {
  const verifier = process.env.VERIFIER_ADDRESS!;
  const token = process.env.TOKEN_ADDRESS!;

  const TipEscrow = await ethers.getContractFactory("TipEscrow");
  const escrow = await TipEscrow.deploy(token, verifier);
  await escrow.waitForDeployment();

  console.log("TipEscrow deployed to:", await escrow.getAddress());
  console.log("Token:", token);
  console.log("Verifier:", verifier);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
