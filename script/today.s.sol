// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

// import "../src/InfinityDaoLaunchPad.sol";
// import "../src/ethernaut.sol";
// import "../src/ILAUNCHPAD.sol";

import "../src/hack.sol";

// import "../src/IUSDT.sol";

contract today is Script {
    Challenge public challenge;

    function setUp() public {
        challenge = new Challenge();
    }

    function run() public {
        uint answer;
        bool status1;
        for (uint16 i = 55535; i < 64535; i++) {
            challenge.level1(i);
            // if (answer == 0) {
            status1 = challenge.displayHasSolved();
            if (status1 == true) {
                answer = i;
                console.log(answer);
                break;
            }
            console.log(answer);
        }
    }
}

//         IUSDT(0xdf6341244E06F70b2d312574EA04fc4c16f934d9).mint(
//             address(0xBB9F947cB5b21292DE59EFB0b1e158e90859dddb),
//             100000 * 10e18
//         );
// address deployer = 0xA771E1625DD4FAa2Ff0a41FA119Eb9644c9A46C8;
// uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
// vm.startBroadcast(deployerPrivateKey);
// TodaysCTF = new todaysCTF();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
// TodaysCTF.callFlip();
