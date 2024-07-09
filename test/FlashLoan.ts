import { ethers } from "hardhat";

describe("ABasicTest", function () {
  it("GetBlockNumber", async function () {
    // const provider = ethers.provider;
    const provider = new ethers.providers.JsonRpcProvider(
      "http://127.0.0.1:8545"
    );
    const blockNumber = await provider.getBlockNumber();
    console.log("Block Number:", blockNumber);
  });
});
