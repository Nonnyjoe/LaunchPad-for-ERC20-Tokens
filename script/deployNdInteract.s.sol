// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";
// import "../src/infinityPadFactory.sol";
// import "../src/StarDaoToken.sol";
// import "../src/ILAUNCHPAD.sol";

// contract deployLaunchPadFactory is Script {
//     InfinityDaoLaunchPadFactory public infinityDaoLaunchPadFactory;
//     StarDaoToken public starDaoToken;

//     function setUp() public {}

//     function run() public {
//         address deployer = 0xA771E1625DD4FAa2Ff0a41FA119Eb9644c9A46C8;
//         address PadAdmin = 0x13B109506Ab1b120C82D0d342c5E64401a5B6381;
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         uint256 PadAdminPrivateKey = vm.envUint("PRIVATE_KEY2");

//         vm.startBroadcast(deployerPrivateKey);
//         starDaoToken = new StarDaoToken(PadAdmin);
//         infinityDaoLaunchPadFactory = new InfinityDaoLaunchPadFactory(deployer);
//         infinityDaoLaunchPadFactory.registerLaunchPads(
//             PadAdmin,
//             address(starDaoToken),
//             uint(101)
//         );
//         vm.stopBroadcast();

//         vm.startBroadcast(PadAdminPrivateKey);
//         starDaoToken.approve(
//             address(infinityDaoLaunchPadFactory),
//             300000000000000000000000
//         );
//         infinityDaoLaunchPadFactory.createLaunchPad(
//             uint(101),
//             address(starDaoToken),
//             (50000000000000000000000),
//             (250000000000000000000000),
//             (7),
//             10
//         );
//         vm.stopBroadcast();

//         // vm.deal(deployer, 11 ether);
//         vm.startBroadcast(deployerPrivateKey);
//         address child = infinityDaoLaunchPadFactory.getLaunchPadAddress(
//             address(starDaoToken)
//         );
//         ILAUNCHPAD(child).participateWithEth{value: 1 ether}();

//         // vm.warp(8 minutes);
//         // ILAUNCHPAD(child).participateInPresale{value: 0.05 ether}();
//         // vm.stopBroadcast();

//         // vm.startBroadcast(PadAdminPrivateKey);
//         // ILAUNCHPAD(child).WithdrawEther(5 ether);

//         vm.stopBroadcast();
//     }
// }
