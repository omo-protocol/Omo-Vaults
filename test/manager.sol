// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./OMOVaultsManager.sol";

contract TestOMOVaultsManager {
    // Instantiate OMOVaultsManager
    OMOVaultsManager manager = OMOVaultsManager(DeployedAddresses.OMOVaultsManager());

    function testDepositAndWithdraw() public {
        // Create two vaults
        manager.createVault(
            IERC20(address(0x1)), // Mock deposit token address
            IERC20(address(0x2)), // Mock vault asset token address
            100, // Mock vault entry fee basis points
            100 // Mock vault exit fee basis points
        );
        manager.createVault(
            IERC20(address(0x3)), // Mock deposit token address
            IERC20(address(0x4)), // Mock vault asset token address
            200, // Mock vault entry fee basis points
            200 // Mock vault exit fee basis points
        );

        // Deposit into the first vault
        manager.deposit(100, address(0xabc), address(manager.vaults(0))); // Assuming the first vault's address is returned as vaults(0)

        // Deposit into the second vault
        manager.deposit(200, address(0xdef), address(manager.vaults(1))); // Assuming the second vault's address is returned as vaults(1)

        // Retrieve the vaults' balances and verify the deposits
        OMOVaultsManager.VaultData memory vault1 = manager.vaults(0);
        OMOVaultsManager.VaultData memory vault2 = manager.vaults(1);

        // Assert balances
        Assert.equal(vault1.vault.balanceOf(address(this)), 100, "Incorrect balance for vault 1");
        Assert.equal(vault2.vault.balanceOf(address(this)), 200, "Incorrect balance for vault 2");
    }
}
