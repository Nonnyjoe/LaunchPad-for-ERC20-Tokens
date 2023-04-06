// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//this is a two level challenge and you must complete level 1 before attempting Level2
contract Challenge {
    mapping(address => bool) private hasSolved1;
    mapping(address => uint) userPoint;
    address[] public champions;
    mapping(address => string) public Names;

    function level1(uint16 _key) external {
        if (
            keccak256(abi.encode(_key)) ==
            0x913abd2fa66769e4601c20cd3bdea32afc207bfdd6b85faa2b3c5ee7e9317727
        ) {
            hasSolved1[msg.sender] = true;
        }
    }

    function displayHasSolved() external returns (bool) {
        return hasSolved1[msg.sender];
    }

    function level2(string memory _name) external {
        require(hasSolved1[tx.origin], "go back and complete level 1");
        userPoint[tx.origin]++;
        msg.sender.call("");
        require(userPoint[tx.origin] == 4, "try Again");
        string memory name_ = Names[tx.origin];
        if (keccak256(abi.encode(name_)) == keccak256(abi.encode(""))) {
            Names[tx.origin] = _name;
            champions.push(tx.origin);
        }
    }

    function getAllwiners() external view returns (string[] memory _names) {
        _names = new string[](champions.length);
        for (uint i; i < champions.length; i++) {
            _names[i] = Names[champions[i]];
        }
    }
}
