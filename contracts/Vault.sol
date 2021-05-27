// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vault is ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public zapper;

    address public admin;

    constructor() public ERC20("Vault Token", "VT") {
        admin = msg.sender;
    }

    modifier onlyZapper() {
        require(msg.sender == zapper, "only zapper is allowed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin is allowed");
        _;
    }

    function setZapper(address _zapper) public onlyAdmin {
        require(_zapper != address(0), "zapper address is invalid");
        zapper = _zapper;
    }

    function earn() public {}

    function deposit(address token, uint256 _amount) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {}
}
