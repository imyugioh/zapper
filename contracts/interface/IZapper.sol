// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IZapper {
    function ZapIn(
        address,
        address,
        bool,
        uint256
    ) external returns (uint256);

    function ZapInWithEth(address, bool) external payable returns (uint256);
}
