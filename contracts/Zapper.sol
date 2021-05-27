// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interface/UniswapV2.sol";
import "./interface/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Zapper is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public sushiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    IVault public vault;

    constructor(IVault _vault) public {
        require(address(_vault) != address(0), "vault address is invalid");
        vault = _vault;
    }

    function ZapInSingle(
        address inToken,
        address outToken,
        uint256 inAmount
    ) public nonReentrant {
        IERC20(inToken).safeTransferFrom(msg.sender, address(this), inAmount);

        IERC20(inToken).safeApprove(uniRouter, 0);
        IERC20(inToken).safeApprove(uniRouter, inAmount);
        _swapUniswap(inToken, outToken, inAmount);

        uint256 _balance = IERC20(outToken).balanceOf(address(this));
        _transferToVault(outToken, _balance);
    }

    function _transferToVault(address token, uint256 amount) internal {
        IERC20(token).safeApprove(address(vault), 0);
        IERC20(token).safeApprove(address(vault), amount);
        vault.deposit(token, amount);

        uint256 _vaultBalance = vault.balanceOf(address(this));
        vault.transfer(msg.sender, _vaultBalance);
    }

    function ZapInMultiple(
        address inToken,
        address outTokenA,
        address outTokenB,
        uint256 inAmount
    ) public nonReentrant {
        IERC20(inToken).safeTransferFrom(msg.sender, address(this), inAmount);

        uint256 _balance = IERC20(inToken).balanceOf(address(this));

        if (_balance > 0) {
            IERC20(inToken).safeApprove(uniRouter, 0);
            IERC20(inToken).safeApprove(uniRouter, _balance);
            uint256 _amount = _balance.div(2);

            if (inToken != outTokenA) {
                _swapUniswap(inToken, outTokenA, _amount);
            }

            if (inToken != outTokenB) {
                _balance = IERC20(inToken).balanceOf(address(this));
                _swapUniswap(inToken, outTokenB, _amount);
            }
        }

        uint256 _tokenABalance = IERC20(outTokenA).balanceOf(address(this));
        uint256 _tokenBBalance = IERC20(outTokenB).balanceOf(address(this));

        if (_tokenABalance > 0 && _tokenBBalance > 0) {
            IERC20(outTokenA).safeApprove(uniRouter, 0);
            IERC20(outTokenA).safeApprove(uniRouter, _tokenABalance);

            IERC20(outTokenB).safeApprove(uniRouter, 0);
            IERC20(outTokenB).safeApprove(uniRouter, _tokenBBalance);

            UniswapRouterV2(uniRouter).addLiquidity(
                outTokenA,
                outTokenB,
                _tokenABalance,
                _tokenBBalance,
                0,
                0,
                address(this),
                block.timestamp + 60
            );
        }
        address _outToken = IUniswapV2Factory(uniFactory).getPair(outTokenA, outTokenB);
        uint256 _outTokenBalance = IERC20(_outToken).balanceOf(address(this));

        _transferToVault(_outToken, _outTokenBalance);
    }

    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(uniRouter).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    function _swapUniswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(uniRouter).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp.add(60));
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount) internal {
        require(path[1] != address(0));

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp.add(60));
    }
}
