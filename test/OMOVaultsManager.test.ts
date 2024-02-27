import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import { ContractFactory, Contract, BigNumber } from "ethers";



describe("OMOVaultsManager", function () {
    let OMOVaultsManager: ContractFactory;
    let OMOVault: ContractFactory;
    let manager: Contract;
    let vault: Contract;
    let owner: Signer;
    let user: Signer;
    let userAddress: string;
    let vaultAddress: string;

    before(async function () {
        [owner, user] = await ethers.getSigners();
        userAddress = await user.getAddress();

        // Create a new vault
        const ERC20vaultAsset  = await ethers.getContractFactory("Shares");
        const vaultAsset = await ERC20vaultAsset.deploy();
        await vaultAsset.deployed();
        await vaultAsset.initialMint(userAddress, ethers.utils.parseEther("1000"));

        console.log("OMO Token Address: ", vaultAsset.address);        

        // Need to change and add a default usdt token or any other token
        const ERC20depositToken = await ethers.getContractFactory("Shares"); 
        const depositToken = await ERC20depositToken.deploy(); 
        await depositToken.deployed(); 

        console.log("Deposit Token Address: ", depositToken.address);

        const vaultEntryFeeBasisPoints = 1;
        const vaultExitFeeBasisPoints = 1;

        const OMOVaultsManager = await ethers.getContractFactory("OMOVaultsManager");

        manager = await OMOVaultsManager.deploy(vaultAsset.address, depositToken.address, vaultEntryFeeBasisPoints, vaultExitFeeBasisPoints);
        await manager.deployed();

        console.log("Manager Address: ", manager.address);

    });   


    it("should exists a default vault", async function () 
    {
        const defaultVault = await manager.defaultVault()
        vaultAddress = defaultVault;

        console.log("Default Vault: ", defaultVault);

        expect(defaultVault).to.not.be.null;
    });

    it("should deposit into the vault", async function () {
        const amount = ethers.utils.parseEther("1");
        await manager.connect(user).pledge(amount, userAddress, vaultAddress);

        const pendingDeposits = await manager.depositBatches(1);
        expect(pendingDeposits.length).to.equal(1);
        /*expect(pendingDeposits[0].amount).to.equal(amount);
        expect(pendingDeposits[0].depositor).to.equal(userAddress);
        expect(pendingDeposits[0].recipient).to.equal(userAddress);
        expect(pendingDeposits[0].vault).to.equal(vaultAddress);*/
    });

    /*it("should withdraw from the vault", async function () {
        const amount = ethers.utils.parseEther("0.5");
        await manager.withdraw(amount, userAddress, vaultAddress);

        const pendingWithdraws = await manager.withdrawBatches(1);
        expect(pendingWithdraws.length).to.equal(1);
        expect(pendingWithdraws[0].amount).to.equal(amount);
        expect(pendingWithdraws[0].recipient).to.equal(userAddress);
        expect(pendingWithdraws[0].vault).to.equal(vaultAddress);
    });

    it("should handle deposit batch", async function () {
        const amount = ethers.utils.parseEther("1");
        await manager.connect(user).pledge(amount, userAddress, vaultAddress);

        await manager.handleDepositBatch(1);

        const pendingDeposits = await manager.depositBatches(1);
        expect(pendingDeposits.length).to.equal(0);
    });

    it("should handle withdraw batch", async function () {
        const amount = ethers.utils.parseEther("0.5");
        await manager.withdraw(amount, userAddress, vaultAddress);

        await manager.handleWithdrawBatch(1);

        const pendingWithdraws = await manager.withdrawBatches(1);
        expect(pendingWithdraws.length).to.equal(0);
    });*/
});
