import { ethers, network } from "hardhat";

async function main() {
  const routerAddress = "0x2626664c2603336E57B271c5C0b26F421741e481";
  const factoryAddress = "0x33128a8fC17869897dcE68Ed026d694621f6FDfD";
  const wethAddress = "0x4200000000000000000000000000000000000006";
  // Replace with the whale's address you want to impersonate
  const whaleAddress = "0x816f722424B49Cf1275cc86DA9840Fbd5a6167e9";

  // Deploy FlashLoanBase contract
  const FlashLoanBaseFactory = await ethers.getContractFactory("FlashLoanBase");
  const flashLoanBase = await FlashLoanBaseFactory.deploy(
    routerAddress,
    factoryAddress,
    wethAddress
  );

  await flashLoanBase.deployed();

  console.log("FlashLoanBase deployed to:", flashLoanBase.address);

  // Impersonate the whale account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [whaleAddress],
  });

  // Get the signer for the impersonated account
  const whaleSigner = await ethers.getSigner(whaleAddress);

  // Perform operations as the whale
  console.log(`Impersonating whale account: ${whaleAddress}`);
  console.log(
    `Whale account balance: ${ethers.utils.formatEther(
      await whaleSigner.getBalance()
    )} ETH`
  );

  // Example params for initFlash function
  const flashParams = {
    token0: "0x816f722424B49Cf1275cc86DA9840Fbd5a6167e9",
    token1: "0x6985884C4392D348587B19cb9eAAf157F13271cd",
    fee1: 3000,
    amount0: ethers.utils.parseUnits("10000", 18),
    amount1: ethers.utils.parseUnits("10000", 18),
    fee2: 500,
    fee3: 1000,
  };

  // Call initFlash function
  const tx = await flashLoanBase.initFlash(flashParams);
  await tx.wait();

  console.log("initFlash function called successfully");
  // Stop impersonating after use (optional)
  await network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [whaleAddress],
  });

  console.log(`Stopped impersonating: ${whaleAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
