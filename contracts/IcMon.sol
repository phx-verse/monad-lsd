// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IcMon is IERC20 {
    function lsdmint(address to, uint256 amount) external;
    function lsdburn(address account, uint256 amount) external;
}