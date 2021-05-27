// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    address public want;
    address public governance;
    address public controller;

    constructor(
        address _want,
        address _governance,
        address _controller
    ) public {
        require(_want != address(0), "invalid want token");
        require(_governance != address(0), "invalid governance");
        want = _want;
        governance = _governance;
        controller = _controller;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance is allowed");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setController(address _controller) external onlyGovernance {
        controller = _controller;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {}

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function withdrawAll() external returns (uint256 balance) {}

    function _withdrawAll() internal {}

    function harvest() public {}

    function deposit() public {}

    function withdraw(uint256 _amount) external {}

    function _withdrawSome(uint256 _amount) internal returns (uint256) {}

    function withdrawToVault(uint256 amount) external onlyGovernance {}

    function withdraw(IERC20 _asset) external returns (uint256 balance) {}
}
