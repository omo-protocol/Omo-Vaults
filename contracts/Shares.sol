// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Shares is ERC20 {
    address public minter;
    address public redemptionReceiver;
    address public merkleClaim;

    constructor() ERC20("omo", "OMO") {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can call this function");
        _;
    }

    modifier onlyReceiver() {
        require(msg.sender == redemptionReceiver || msg.sender == merkleClaim, "Only redemption receiver or merkle claim can call this function");
        _;
    }

    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }

    function setRedemptionReceiver(address _receiver) external onlyMinter {
        redemptionReceiver = _receiver;
    }

    function setMerkleClaim(address _merkleClaim) external onlyMinter {
        merkleClaim = _merkleClaim;
    }

    function initialMint(address _recipient, uint _amount) external onlyMinter {
        require(totalSupply() == 0, "Initial minting can only be done once");
        _mint(_recipient, _amount);
    }

    function transferFrom(address _from, address _to, uint _value) public override returns (bool) {
        uint allowed_from = allowance(_from, msg.sender);
        if (allowed_from != type(uint).max) {
            _approve(_from, msg.sender, allowed_from - _value);
        }
        return super.transferFrom(_from, _to, _value);
    }

    function mint(address account, uint amount) external onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function claim(address account, uint amount) external onlyReceiver returns (bool) {
        _mint(account, amount);
        return true;
    }
}
