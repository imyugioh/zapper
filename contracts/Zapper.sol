// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interface/UniswapV2.sol";
import "./interface/IVault.sol";
import "./interface/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";

contract Zapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public sushiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    function ZapInWithEth(address outToken, bool isPairToken) external payable returns (uint256) {
        IWETH(weth).deposit{value: msg.value}();
        uint256 _wethBalance = IERC20(weth).balanceOf(address(this));
        return ZapIn(weth, outToken, isPairToken, _wethBalance);
    }

    function ZapIn(
        address inToken,
        address outToken,
        bool isPairToken,
        uint256 inAmount
    ) public returns (uint256) {
        uint256 _balance = IERC20(inToken).balanceOf(address(this));
        if (_balance < inAmount) IERC20(inToken).safeTransferFrom(msg.sender, address(this), inAmount);

        if (isPairToken) return ZapInLpToken(inToken, outToken);
        return ZapInSingleToken(inToken, outToken);
    }

    function ZapInSingleToken(address inToken, address outToken) internal returns (uint256) {
        uint256 _inBalance = IERC20(inToken).balanceOf(address(this));
        console.log("   [ZapInSingleToken] inToken %s, outToken %s", inToken, outToken);

        IERC20(inToken).safeApprove(uniRouter, 0);
        IERC20(inToken).safeApprove(uniRouter, _inBalance);
        console.log("   [ZapInSingleToken] _inBalance => ", _inBalance);
        _swapUniswap(inToken, outToken, _inBalance);

        uint256 _outBalance = IERC20(outToken).balanceOf(address(this));
        console.log("   [ZapInSingleToken] _outBalance => ", _outBalance);
        IERC20(outToken).safeTransfer(msg.sender, _outBalance);

        return _outBalance;
    }

    function ZapInLpToken(address inToken, address outToken) internal returns (uint256) {
        address tokenA = IUniswapV2Pair(outToken).token0();
        address tokenB = IUniswapV2Pair(outToken).token1();

        uint256 _balance = IERC20(inToken).balanceOf(address(this));

        if (_balance > 0) {
            IERC20(inToken).safeApprove(uniRouter, 0);
            IERC20(inToken).safeApprove(uniRouter, _balance);

            if (inToken == tokenA) {
                _swapUniswap(inToken, tokenB, _balance.div(2));
            } else if (inToken == tokenB) {
                _swapUniswap(inToken, tokenA, _balance.div(2));
            } else {
                uint256 _amount = _balance.div(2);
                _swapUniswap(inToken, tokenA, _amount);

                _balance = IERC20(inToken).balanceOf(address(this));
                _swapUniswap(inToken, tokenB, _amount);
            }
        }

        uint256 _tokenABalance = IERC20(tokenA).balanceOf(address(this));
        uint256 _tokenBBalance = IERC20(tokenB).balanceOf(address(this));

        if (_tokenABalance > 0 && _tokenBBalance > 0) {
            IERC20(tokenA).safeApprove(uniRouter, 0);
            IERC20(tokenA).safeApprove(uniRouter, _tokenABalance);

            IERC20(tokenB).safeApprove(uniRouter, 0);
            IERC20(tokenB).safeApprove(uniRouter, _tokenBBalance);

            UniswapRouterV2(uniRouter).addLiquidity(
                tokenA,
                tokenB,
                _tokenABalance,
                _tokenBBalance,
                0,
                0,
                address(this),
                block.timestamp + 60
            );
        }

        uint256 _outTokenBalance = IERC20(outToken).balanceOf(address(this));

        IERC20(outToken).safeTransfer(msg.sender, _outTokenBalance);

        return _outTokenBalance;
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

    function _swapUniswapWithETH(uint256 _ethAmount, address _to) internal {
        require(_to != address(0));

        address[] memory path = new address[](2);

        path[0] = weth;
        path[1] = _to;

        UniswapRouterV2(uniRouter).swapExactETHForTokens{value: _ethAmount}(
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
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

    function _swapSushiswapWithETH(uint256 _ethAmount, address _to) internal {
        require(_to != address(0));

        address[] memory path = new address[](2);

        path[0] = weth;
        path[1] = _to;

        UniswapRouterV2(sushiRouter).swapExactETHForTokens{value: _ethAmount}(
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }
}
