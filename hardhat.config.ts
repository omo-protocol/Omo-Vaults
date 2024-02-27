import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";
import {resolve} from "path";
import {config as dotenvConfig} from "dotenv";
import {HardhatUserConfig, task} from "hardhat/config";
import { ethers } from "ethers";

dotenvConfig({path: resolve(__dirname, "./.env")});

if( ! process.env.PRIVATE_KEY  ){
    throw new Error("No private key in .env file");
}

const config: HardhatUserConfig = {
    networks: {
        hardhat: {
            initialBaseFeePerGas: 0,
        },
        mainnet: {
            url: process.env.RPC_MAINNET,
            accounts: [process.env.PRIVATE_KEY!]
        },
        testnet: {
            url: process.env.RPC_TESTNET,
            accounts: [process.env.PRIVATE_KEY!],
            gasPrice: 10000000000,
        },

    },
    solidity: {
        version: "0.8.19",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    etherscan: {
        apiKey: `${process.env.SCAN}`
    }
};

task("initialMint", "Calls the initialMint function on the contract")
    .addParam("contract", "The address of the contract")
    .addParam("recipient", "The recipient address")
    .addParam("amount", "The amount to mint")
    .setAction(async (taskArgs, hre) => {
        const signers = await hre.ethers.getSigners();
        const contract = new ethers.Contract(taskArgs.contract, ['function initialMint(address,uint256)'], signers[0]);
        const result = await contract.initialMint(taskArgs.recipient, taskArgs.amount);
        console.log("Transaction:", result);
    });


task("mint", "Calls the mint function on the contract")
    .addParam("contract", "The address of the contract")
    .addParam("recipient", "The recipient address")
    .addParam("amount", "The amount to mint")
    .setAction(async (taskArgs, hre) => {
        const signers = await hre.ethers.getSigners();
        const contract = new ethers.Contract(taskArgs.contract, ['function mint(address,uint256)'], signers[0]);
        const result = await contract.mint(taskArgs.recipient, taskArgs.amount);
        console.log("Transaction:", result);
    });


export default config;
