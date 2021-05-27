// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);
}
