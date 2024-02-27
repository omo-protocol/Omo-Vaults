// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

contract OMOVaultsManager {
    struct PendingDeposit {
        uint256 amount;
        address depositor;
        address recipient;
        address vault; 
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
        OMOVaults vault;
    }

    mapping(address => VaultData) public vaults;

    function createVault(
        IERC20 depositToken,
        IERC20 vaultAsset,
        uint256 vaultEntryFeeBasisPoints,
        uint256 vaultExitFeeBasisPoints
    ) external {

        require(address(vaults[address(newVault)].vault) == address(0), "vault already exists");
        batchManager = msg.sender;

        OMOVaults newVault = new OMOVaults(
            depositToken,
            vaultAsset,
            vaultEntryFeeBasisPoints,
            vaultExitFeeBasisPoints
        );
        vaults[address(newVault)] = VaultData(newVault);
    }

    function deposit(uint256 amount, address recipient, address vault) external {
        // Assume vault address is valid and exists in the system
        require(vaults[vault].vault != address(0), "Vault does not exist");

        depositBatches[currentDepositBatch].push(PendingDeposit({
            amount: amount,
            depositor: msg.sender,
            recipient: recipient,
            vault: vault
        }));
    }

    function withdraw(uint256 amount, address recipient, address vault) external {
        // Assume vault address is valid and exists in the system
        require(vaults[vault].vault != address(0), "Vault does not exist");

        withdrawBatches[currentWithdrawBatch].push(PendingWithdraw({
            amount: amount,
            recipient: recipient,
            vault: vault
        }));
    }

    function handleDepositBatch(uint256 batchNumber) external onlyBatchManager {
        require(depositBatchState[batchNumber] == BatchState.started);
        depositBatchState[batchNumber] = BatchState.pending;
        currentDepositBatch++;
        uint256 total = 0;
        for (uint256 i = 0; i < depositBatches[batchNumber].length; i++) {
            // Deposit funds into the selected vault
            OMOVaults vault = vaults[depositBatches[batchNumber][i].vault].vault;
            vault.deposit(depositBatches[batchNumber][i].amount, depositBatches[batchNumber][i].recipient);
            total += depositBatches[batchNumber][i].amount;
        }

        // Perform any additional actions if needed

        depositBatchState[batchNumber] = BatchState.completed;
    }

    function handleWithdrawBatch(uint256 batchNumber) external onlyBatchManager {
        require(withdrawBatchState[batchNumber] == BatchState.started);
        withdrawBatchState[batchNumber] = BatchState.pending;
        currentWithdrawBatch++;
        for (uint256 i = 0; i < withdrawBatches[batchNumber].length; i++) {
            // Withdraw funds from the selected vault
            OMOVaults vault = vaults[withdrawBatches[batchNumber][i].vault].vault;
            vault.withdraw(withdrawBatches[batchNumber][i].amount, withdrawBatches[batchNumber][i].recipient);
        }

        // Perform any additional actions if needed

        withdrawBatchState[batchNumber] = BatchState.completed;
    }


    
}
