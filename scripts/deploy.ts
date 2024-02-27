const { ethers } = require("hardhat");

async function main() {
    const MyToken = await ethers.getContractFactory("Token");
    const myToken = await MyToken.deploy();
    await myToken.deployed();

    console.log("MyToken deployed to:", myToken.address);

    const minter = await myToken.minter();
    console.log("Minter address:", minter);

    const redemptionReceiver = await myToken.redemptionReceiver();
    console.log("Redemption receiver address:", redemptionReceiver);

    const merkleClaim = await myToken.merkleClaim();
    console.log("Merkle claim address:", merkleClaim);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
