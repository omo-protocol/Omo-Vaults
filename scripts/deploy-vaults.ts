

async function mainVault() {

    const ERC4626Fees = await ethers.getContractFactory("OMOVault");
    const vaultAssetAddress = ethers.utils.getAddress("0x17040d4a743cbffafdc7776333fdbca8dcfeb6dc"); // Replace with the actual address of the vault asset
    const vaultEntryFeeBasisPoints = 2; // Replace with the desired entry fee basis points
    const vaultExitFeeBasisPoints = 1; // Replace with the desired exit fee basis points

    console.log("Deploying OMOVault with the following parameters:");
    console.log("Vault Asset Address:", vaultAssetAddress);
    console.log("Vault Entry Fee Basis Points:", vaultEntryFeeBasisPoints);
    console.log("Vault Exit Fee Basis Points:", vaultExitFeeBasisPoints);

    const erc4626Fees = await ERC4626Fees.deploy(
        vaultAssetAddress,
        vaultEntryFeeBasisPoints,
        vaultExitFeeBasisPoints
    );

    await erc4626Fees.deployed();

    console.log("ERC4626Fees deployed to:", erc4626Fees.address);
}

mainVault()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});