import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, network } from "hardhat";

import { abi as abiFlashLoan } from "../artifacts/contracts/FlashLoan.sol/FlashLoan.json";

const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
const v3Fee = 500;

describe("BSCFlashLoanPancakeSwap", function () {
  describe("Deployment and perform Flash loan arbitrage", function () {
    it("Deploys and get pool address", async function () {
      const FlashLoan = await ethers.getContractFactory("FlashLoan");
      let flashLoan = await FlashLoan.deploy(WBNB, BUSD, v3Fee);
      await flashLoan.deployed();
      console.log("FlashLoan Contract Deployed:\t", flashLoan.address);

      //Initialize Flash Loan Params
      const amountBorrow = ethers.utils.parseUnits("30", 18);
      const tokenPath = [CAKE, WBNB];
      const routing = [1, 0, 0];
      const feeV3 = 500;

      // Signer

      const [signer] = await ethers.getSigners();

      // Connect to FlashLoan contract

      const contractFlashLoan = new ethers.Contract(
        flashLoan.address,
        abiFlashLoan,
        signer
      );

      // Call FlashLoan Request Function
      const txFlashLoan = await contractFlashLoan.flashLoanRequest(
        tokenPath,
        0,
        amountBorrow,
        feeV3,
        routing
      );

      //Show Results

      const txFlashloanReceipt = await txFlashLoan.wait();
      expect(txFlashloanReceipt.status).to.eq(1);
    });
  });
});
