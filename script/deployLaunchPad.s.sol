// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/LaunchPad.sol";
import "../src/StarDaoToken.sol";

contract deployLaunchPad is Script {
    LaunchPad public launchPad;

    StarDaoToken public starDaoToken;

    function setUp() public {}

    function run() public {
        address deployer = 0xA771E1625DD4FAa2Ff0a41FA119Eb9644c9A46C8;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        launchPad = new LaunchPad();
        starDaoToken = new StarDaoToken();
    }
}
