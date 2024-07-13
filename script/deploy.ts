import { ethers, network } from "hardhat";

async function main() {
  const routerAddress = "0x2626664c2603336E57B271c5C0b26F421741e481"; // Replace with actual router address
  const factoryAddress = "0x33128a8fC17869897dcE68Ed026d694621f6FDfD"; // Replace with actual factory address
  const wethAddress = "0x4200000000000000000000000000000000000006"; // Replace with actual WETH9 address
  const payer = ""; // Specify the payer address if needed

  // Deploy FlashLoanBase contract
  const FlashLoanBaseFactory = await ethers.getContractFactory("FlashLoanBase");
  const flashLoanBase = await FlashLoanBaseFactory.deploy(
    routerAddress,
    factoryAddress,
    wethAddress
  );

  await flashLoanBase.deployed();

  console.log("FlashLoanBase deployed to:", flashLoanBase.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
