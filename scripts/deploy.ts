import { ethers } from "hardhat";

async function main() {
  const MultiSigWallet = await ethers.deployContract("MultiSigWallet");
  await MultiSigWallet.waitForDeployment();
  console.log(`Success Deployed:`, MultiSigWallet.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
