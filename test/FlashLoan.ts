import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, network } from "hardhat";

import { abi as abiFlashLoan } from "../artifacts/contracts/FlashLoan.sol/FlashLoan.json";

const WHALE_ADDRESS_BUSD = "0xdF1Fd1Ea608F910B1bD6Ca68163f9E817F752af0";
const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
const v3Fee = 500;
const BORROW_TOKEN = BUSD;
describe("BSCFlashLoanPancakeSwap", function () {
  async function create_whale() {
    const provider = ethers.provider;
    const whaleBalance = await provider.getBalance(WHALE_ADDRESS_BUSD);
    expect(whaleBalance).not.equal("0");

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [WHALE_ADDRESS_BUSD],
    });
    const whaleWallet = ethers.provider.getSigner(WHALE_ADDRESS_BUSD);
    expect(whaleWallet.getBalance).not.equal("0");

    // Ensure BUSD Balance

    const abi = [
      "function balanceOf(address _owner) view returns (uint256 balance)",
    ];
    const contractBusd = new ethers.Contract(BORROW_TOKEN, abi, provider);
    const balanceBusd = await contractBusd.balanceOf(WHALE_ADDRESS_BUSD);
    console.log("Balance BUSD Whale:", balanceBusd);
    expect(balanceBusd).not.equal("0");

    //     // Return output
    return { whaleWallet };
  }
  describe("Deployment and Testing", function () {
    it("Deploys and perform flash loan arbitrage", async function () {
      let { whaleWallet } = await loadFixture(create_whale);

      //Deploy
      const FlashLoan = await ethers.getContractFactory("FlashLoan");
      let flashLoan = await FlashLoan.deploy(WBNB, BUSD, v3Fee);
      await flashLoan.deployed();
      console.log("FlashLoan Contract Deployed:\t", flashLoan.address);

      // Send BUSD for fake Arbitrage Calculation (Smart Contract then should work)
      let usdAmt = ethers.utils.parseUnits("20", 18);
      const abi = [
        "function transfer(address _to, uint256 _value) public returns (bool success)",
        "function balanceOf(address _owner) view returns (uint256 balance)",
      ];
      const contractBusd = new ethers.Contract(BORROW_TOKEN, abi, whaleWallet);
      const txTransferBusd = await contractBusd.transfer(
        flashLoan.address,
        usdAmt
      );
      const receiptTxBusd = await txTransferBusd.wait();
      expect(receiptTxBusd.status).to.eq(1);

      const contractBalanceBusd = await contractBusd.balanceOf(
        flashLoan.address
      );
      console.log("Wallet BUSD : \t\t", contractBalanceBusd);

      //Initialize Flash Loan Params
      const amountBorrow = ethers.utils.parseUnits("30", 18);
      const tokenPath = [CAKE, WBNB];
      const routing = [1, 0, 0];
      const feeV3 = 500;

      // Signer

      // const [signer] = await ethers.getSigners();

      // Connect to FlashLoan contract

      const contractFlashLoan = new ethers.Contract(
        flashLoan.address,
        abiFlashLoan,
        whaleWallet
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

      const contractBalanceBusdAfter = await contractBusd.balanceOf(
        flashLoan.address
      );
      console.log("Wallet BUSD After: \t\t", contractBalanceBusdAfter);
    });
  });
});
