// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./OMOVault.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OMOVaultsManager is ReentrancyGuard {

    address public WETH = address(0x04C154b66CB340F3Ae24111CC767e0184Ed00Cc6);
    event DepositBatchesChanged(uint256 index, bool completed);
    event WithdrawBatchesChanged(uint256 index, bool completed);
    
    struct PendingDeposit {
        uint256 amount;
        address depositor;
        address recipient;
        address vault; 
        uint256 timestamp; 
    }

    struct PendingWithdraw {
        uint256 amount;
        address recipient;
        address vault; 
    }

    struct DepositResults {
        address recipient;
        uint256 sharesAmount;
    }

    enum BatchState {
        started,
        pending,
        completed
    }

    address public batchManager;
    address public defaultVault;

    modifier onlyBatchManager() {
        require(msg.sender == batchManager, "only batch manager");
        _;
    }

    mapping(uint256 => PendingDeposit[]) public depositBatches;
    mapping(uint256 => PendingWithdraw[]) public withdrawBatches;
    uint256 public currentDepositBatch;
    uint256 public currentWithdrawBatch;
    mapping(uint256 => BatchState) public depositBatchState;
    mapping(uint256 => BatchState) public withdrawBatchState;

    struct VaultData {
        OMOVault vault;
    }

    mapping(address => VaultData) public vaults;
 
    constructor(
        IERC20 depositToken,
        IERC20 vaultAsset,
        uint256 vaultEntryFeeBasisPoints,
        uint256 vaultExitFeeBasisPoints) {
        currentDepositBatch = 1;
        currentWithdrawBatch = 1;
        
        batchManager = msg.sender;

        OMOVault newVault = new OMOVault(
            depositToken,
            vaultAsset,
            vaultEntryFeeBasisPoints,
            vaultExitFeeBasisPoints
        );
        vaults[address(newVault)] = VaultData(newVault);
        defaultVault = address(newVault);
    }
    

    function createVault (
        IERC20 depositToken,
        IERC20 vaultAsset,
        uint256 vaultEntryFeeBasisPoints,
        uint256 vaultExitFeeBasisPoints
    ) external onlyBatchManager {
        require(msg.sender == batchManager, "only batch manager");
        OMOVault newVault = new OMOVault(
            depositToken,
            vaultAsset,
            vaultEntryFeeBasisPoints,
            vaultExitFeeBasisPoints
        );
        vaults[address(newVault)] = VaultData(newVault);
    }
    
    function getFirstVaultValue() external view returns (OMOVault) {
       
    }

    function pledge(uint256 amount, address recipient, address vaultAddr) external payable nonReentrant {
       
        require(vaults[vaultAddr].vault != OMOVault(address(0)), "Vault does not exist");

        if(recipient == address(0)) {
            recipient = WETH;
        }

        depositBatches[currentDepositBatch].push(PendingDeposit({
            amount: amount,
            depositor: msg.sender,
            recipient: recipient,
            vault: vaultAddr,
            timestamp: block.timestamp 
        }));

        IERC20 depositToken = vaults[vaultAddr].vault.depositToken();
        depositToken.transferFrom(msg.sender, address(this), amount);

        emit DepositBatchesChanged(currentDepositBatch, false);
    }


    function withdraw(uint256 amount, address recipient, address vault) external {
        // Assume vault address is valid and exists in the system

        withdrawBatches[currentWithdrawBatch].push(PendingWithdraw({
            amount: amount,
            recipient: recipient,
            vault: vault
        }));

        // TODO: Working on this logic
        emit WithdrawBatchesChanged(currentWithdrawBatch, false);

    }



    // Agents Batchs Into Vaults Processing
    function handleDepositBatch(uint256 batchNumber) external onlyBatchManager {
        require(depositBatchState[batchNumber] == BatchState.started);
        depositBatchState[batchNumber] = BatchState.pending;
        currentDepositBatch++;
        uint256 total = 0;
        for (uint256 i = 0; i < depositBatches[batchNumber].length; i++) {
            // Check if the latency period has passed
            if (block.timestamp >= depositBatches[batchNumber][i].timestamp + 60 seconds) {
                // Deposit funds into the selected vault

                OMOVault vault = vaults[depositBatches[batchNumber][i].vault].vault;
                vault._deposit(depositBatches[batchNumber][i].amount, depositBatches[batchNumber][i].recipient);
                total += depositBatches[batchNumber][i].amount;
            }
        }

        depositBatchState[batchNumber] = BatchState.completed;
        emit DepositBatchesChanged(currentDepositBatch, true);
    }

    function handleWithdrawBatch(uint256 batchNumber) external onlyBatchManager {
        require(withdrawBatchState[batchNumber] == BatchState.started);
        withdrawBatchState[batchNumber] = BatchState.pending;
        currentWithdrawBatch++;
        for (uint256 i = 0; i < withdrawBatches[batchNumber].length; i++) {

            OMOVault vault = vaults[withdrawBatches[batchNumber][i].vault].vault;          
            
            vault.processWithdraw(
                withdrawBatches[batchNumber][i].recipient,
                withdrawBatches[batchNumber][i].recipient,
                msg.sender,
                withdrawBatches[batchNumber][i].amount,
                0
            );
        }


        withdrawBatchState[batchNumber] = BatchState.completed;
        emit WithdrawBatchesChanged(batchNumber, true);
    }
}
