// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract OMOVault is ERC4626 {
    using Math for uint256;

    event Deposit(uint256 index, address caller, address receiver, uint256 assets, uint256 shares);
    event Withdraw(uint256 index, address caller, address receiver, uint256 assets, uint256 shares);

    uint256 private constant _BASIS_POINT_SCALE = 1e4;
    uint256 public entryFeeBasisPoints;
    uint256 public exitFeeBasisPoints;
    address public treasury;
    uint256 public index = 0;  

    IERC20 public depositToken;
    mapping(address => uint256) public depositTimestamp; 


    constructor(
        IERC20 _depositToken,
        IERC20 _vaultAsset,
        uint256 _vaultEntryFeeBasisPoints,
        uint256 _vaultExitFeeBasisPoints
    ) 

        ERC4626(_vaultAsset) ERC20("OMO Vault", "oVAULT") {
        depositToken = _depositToken;
        entryFeeBasisPoints = _vaultEntryFeeBasisPoints;
        exitFeeBasisPoints = _vaultExitFeeBasisPoints;
        treasury = msg.sender;
        
    }

    modifier onlyOwner() {
        require(msg.sender == treasury, "Only treasury can call this function");
        _;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    // === Overrides ===

    /// @dev Preview taking an entry fee on deposit.
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());
        return super.previewDeposit(assets - fee);
    }

    /// @dev Preview adding an entry fee on mint.
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewMint(shares);
        return assets + _feeOnRaw(assets, _entryFeeBasisPoints());
    }

    /// @dev Preview adding an exit fee on withdraw.
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        if (block.timestamp <= depositTimestamp[msg.sender] + 48 hours) {
            // Apply 5% withdrawal fee if within the first 48 hours
            uint256 fee = assets.mul(5).div(100);
            return assets.sub(fee);
        } else {
            return assets;
        }
    }

    /// @dev Preview taking an exit fee on redeem.
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        return assets - _feeOnTotal(assets, _exitFeeBasisPoints());
    }

    /// @dev Send entry fee to {_entryFeeRecipient}.
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());
        address recipient = _entryFeeRecipient();

        super._deposit(caller, receiver, assets, shares);

        if (fee > 0 && recipient != address(this)) {
            SafeERC20.safeTransfer(IERC20(asset()), recipient, fee);
        }
        
        depositTimestamp[receiver] = block.timestamp;
        emit Deposit(index, caller, receiver, assets, shares);
        index++;
    }

    /// @dev Send exit fee to {_exitFeeRecipient}.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        uint256 fee;
        if (block.timestamp <= depositTimestamp[receiver] + 48 hours) {
            fee = assets.mul(5).div(100);
        }

        uint256 netAssets = assets.sub(fee);
        address recipient = _exitFeeRecipient();

        super._withdraw(caller, receiver, owner, netAssets, shares);

        if (fee > 0 && recipient != address(this)) {
            SafeERC20.safeTransfer(IERC20(asset()), recipient, fee);
        }

        emit Withdraw(index, caller, receiver, assets, shares);
        index++;
    }

    // === Fee configuration ===

    function _entryFeeBasisPoints() internal view virtual returns (uint256) {
        return entryFeeBasisPoints;
    }

    function _exitFeeBasisPoints() internal view virtual returns (uint256) {
        return exitFeeBasisPoints; 
    }

    function _entryFeeRecipient() internal view virtual returns (address) {
        return address(treasury);
    }

    function _exitFeeRecipient() internal view virtual returns (address) {
        return address(treasury);
    }

    // === Fee operations ===

    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) private pure returns (uint256) {
        return assets.mulDiv(feeBasisPoints, _BASIS_POINT_SCALE, Math.Rounding.Up);
    }

    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) private pure returns (uint256) {
        return assets.mulDiv(feeBasisPoints, feeBasisPoints + _BASIS_POINT_SCALE, Math.Rounding.Up);
    }
}
