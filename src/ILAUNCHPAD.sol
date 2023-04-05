// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILAUNCHPAD {
    function participateWithEth() external payable;

    function participateInPresale() external payable;

    function WithdrawEther(uint _amount) external;

    function flip(bool) external returns (bool);

    function callFlip() external;
}
