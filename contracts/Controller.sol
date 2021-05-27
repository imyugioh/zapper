// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IStrategy.sol";
import "./interface/IConverter.sol";

contract Controller {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;

    address public governance;

    constructor(address _governance) public {
        require(_governance != address(0), "invalid gov");
        governance = _governance;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }

    function setVault(address _token, address _vault) public onlyGovernance {
        require(vaults[_token] == address(0), "vault is already set");
        vaults[_token] = _vault;
    }

    function setStrategy(address _token, address _strategy) public onlyGovernance {
        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    function setConverter(
        address _input,
        address _output,
        address _converter
    ) public onlyGovernance {
        converters[_input][_output] = _converter;
    }

    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = IConverter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public onlyGovernance {
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public onlyGovernance {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public onlyGovernance {
        IStrategy(_strategy).withdraw(_token);
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance is allowed");
        _;
    }
}
