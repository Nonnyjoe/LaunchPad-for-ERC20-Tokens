// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "../lib/forge-std/src/Test.sol";
// import "../oldVersion/InfinityDaoLaunchPad.sol";
// import "../src/StarDaoToken.sol";
// // import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

// contract LaunchPadFunctionalityTest is Test {
//     using SafeMath for uint256;
//     InfinityDaoLaunchPad public infinityDaoLaunchPad;
//     StarDaoToken public starDaoToken;
//     uint tokken3;
//     uint tokken4;
//     address Admin = address(0xfd182E53C17BD167ABa87592C5ef6414D25bb9B4);
//     address padCreator = mkaddr("padCreator");
//     address participator1 = mkaddr("participator1");
//     address participator2 = mkaddr("participator2");
//     address participator3 = mkaddr("participator3");
//     address participator4 = mkaddr("participator4");
//     address participator5 = mkaddr("participator5");

//     function setUp() public {
//         vm.startPrank(Admin);
//         infinityDaoLaunchPad = new InfinityDaoLaunchPad();
//         starDaoToken = new StarDaoToken();
//         vm.stopPrank();
//     }

//     function testCreateLaunchPad() public {
//         prepareToken();
//         vm.startPrank(padCreator);
//         infinityDaoLaunchPad.createLaunchPad(
//             uint(101),
//             address(starDaoToken),
//             (100000 * 10e18),
//             (50000 * 10e18),
//             5,
//             10
//         );
//         vm.stopPrank();
//     }

//     function testParticipateWithEth() public {
//         testCreateLaunchPad();
//         participate(participator1, 101, 0.2 ether);
//         participate(participator2, 101, 0.5 ether);
//         participate(participator3, 101, 0.6 ether);
//         participate(participator4, 101, 0.8 ether);
//         participate(participator5, 101, 1 ether);
//     }

//     function testwithdrawPadToken() public {
//         testParticipateWithEth();
//         vm.warp(6 minutes);
//         uint tokken1 = withdrawPadTokken(participator1, 101);
//         uint tokken2 = withdrawPadTokken(participator2, 101);
//         tokken3 = withdrawPadTokken(participator3, 101);
//         tokken4 = withdrawPadTokken(participator4, 101);
//     }

//     function testSwapPadTokenToEthB4Withdrawal() public {
//         testwithdrawPadToken();
//         SwapBackBeforeWithdrawal(participator5, 101);
//     }

//     function testSwapPadTokenToEthAfterWithdrawal() public {
//         testwithdrawPadToken();
//         SwapBackAfterWithdrawal(participator3, 101, tokken3);
//         SwapBackAfterWithdrawal(participator4, 101, tokken4);
//     }

//     function testDisplayContributors() public {
//         testParticipateWithEth();
//         infinityDaoLaunchPad.displayNoOfContributors(101);
//     }

//     function testViewEthRaised() public {
//         testParticipateWithEth();
//         infinityDaoLaunchPad.viewEthRaised(101);
//     }

//     function testTotalLaunchPads() public {
//         testParticipateWithEth();
//         infinityDaoLaunchPad.totalLaunchPads();
//     }

//     function testViewFees() public {
//         testwithdrawPadToken();
//         vm.prank(Admin);
//         infinityDaoLaunchPad.viewFees();
//     }

//     function testdisplayAllLaunchPads() public {
//         testParticipateWithEth();
//         infinityDaoLaunchPad.displayAllLaunchPads();
//     }

//     function testparticipateInPresale() public {
//         testwithdrawPadToken();
//         vm.deal(address(0x01), 0.5 ether);
//         runPreSale(address(0x01), 101, 0.5 ether);
//     }

//     function testEndPresale() public {
//         testparticipateInPresale();
//         vm.startPrank(padCreator);
//         infinityDaoLaunchPad.endPresale(101);
//         uint rate = infinityDaoLaunchPad.displayRateFromLaunchPad(101);
//         uint EthRaised = infinityDaoLaunchPad.viewEthRaisedFromPresale(101);
//         uint TokenBal = infinityDaoLaunchPad.viewPresaleTokenBalance(101);
//         console.log(rate);
//         console.log(EthRaised);
//         console.log(TokenBal);
//         vm.stopPrank();
//     }

//     function testWithdrawExcess() public {
//         testEndPresale();
//         vm.startPrank(padCreator);
//         infinityDaoLaunchPad.withdrawExcessPresaleTokken(101);
//         vm.stopPrank();
//     }

//     //  322580 645161290322580645
//     //   500000000000000000
//     //   353372434017595307917889

//     function runPreSale(
//         address _participant,
//         uint _id,
//         uint _ammount
//     ) internal {
//         vm.prank(_participant);
//         infinityDaoLaunchPad.participateInPresale{value: _ammount}(_id);
//     }

//     function SwapBackBeforeWithdrawal(address _participant, uint _id) internal {
//         vm.prank(_participant);
//         infinityDaoLaunchPad.SwapPadTokenToEthB4Withdrawal(_id);
//     }

//     function SwapBackAfterWithdrawal(
//         address _participant,
//         uint _id,
//         uint _ammount
//     ) internal {
//         vm.startPrank(_participant);
//         starDaoToken.approve(address(infinityDaoLaunchPad), _ammount);
//         infinityDaoLaunchPad.SwapPadTokenToEthAfterWithdrawal(_id, _ammount);
//         vm.stopPrank();
//     }

//     function withdrawPadTokken(
//         address _participant,
//         uint _id
//     ) internal returns (uint tokkens) {
//         vm.prank(_participant);
//         tokkens = infinityDaoLaunchPad.withdrawPadToken(_id);
//     }

//     function participate(
//         address _participator,
//         uint _id,
//         uint _ammount
//     ) internal {
//         vm.deal(_participator, 2 ether);
//         vm.prank(_participator);
//         infinityDaoLaunchPad.participateWithEth{value: _ammount}(_id);
//     }

//     function prepareToken() internal {
//         vm.prank(Admin);
//         starDaoToken.mint(padCreator, (10000000 * 10e18));
//         vm.prank(padCreator);
//         starDaoToken.approve(address(infinityDaoLaunchPad), (10000000 * 10e18));
//     }

//     function mkaddr(string memory name) public returns (address) {
//         address addr = address(
//             uint160(uint256(keccak256(abi.encodePacked(name))))
//         );
//         vm.label(addr, name);
//         return addr;
//     }
// }
