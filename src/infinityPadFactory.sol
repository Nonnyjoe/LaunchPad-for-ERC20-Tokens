// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUSDT.sol";
import "./infinityDaoPad.sol";

contract InfinityDaoLaunchPadFactory {
    event LaunchPadRegistered(address PadToken, uint regId);
    event launchpadCreated(
        address moderator,
        address padtoken,
        uint padDuration
    );
    error Id_Already_Taken();
    error Cannot_Be_Address_Zero();
    error cannot_Accept_Zero_Value();

    address[] launchpads;
    address ProjectAdmin;

    uint launchPadFee;
    struct padDetails {
        uint LaunchPadStartTime;
        address LaunchpadAddress;
        address LaunchPadAdmin;
    }
    mapping(uint => bool) idIsTaken;
    mapping(address => uint) LaunchpadIdRecord;

    mapping(uint => padDetails) LaunchPadRecord;
    mapping(address => address) TokenToLaunchPadRecord;

    modifier IsAdmin() {
        require(msg.sender == ProjectAdmin, "NOT THE PROJECT ADMIN");
        _;
    }

    modifier onlyVerifiedAdmin(uint regId, address _padToken) {
        require(idIsTaken[regId] == true, "INVALID ID");
        require(
            LaunchPadRecord[regId].LaunchPadAdmin == msg.sender,
            "NOT REGISTERED ADMIN"
        );
        require(
            LaunchPadRecord[regId].LaunchPadStartTime <= block.timestamp,
            "REGISTRATION NOT OPEN YET"
        );
        require(LaunchpadIdRecord[_padToken] == regId, "TOKEN NOT REGISTERED");
        _;
    }

    constructor(address admin, uint _launchPadFees) {
        ProjectAdmin = admin;
        launchPadFee = _launchPadFees;
    }

    function registerLaunchPads(
        address _launchPadAdmin,
        address PadToken,
        uint regId,
        uint _startTime
    ) public IsAdmin {
        if (regId == 0) revert cannot_Accept_Zero_Value();
        if (_launchPadAdmin == address(0) || PadToken == address(0))
            revert Cannot_Be_Address_Zero();
        if (idIsTaken[regId] == true) revert Id_Already_Taken();
        LaunchpadIdRecord[PadToken] = regId;
        LaunchPadRecord[regId].LaunchPadAdmin = _launchPadAdmin;
        LaunchPadRecord[regId].LaunchPadStartTime = _startTime;
        idIsTaken[regId] = true;
        emit LaunchPadRegistered(PadToken, regId);
    }

    function createLaunchPad(
        uint regId,
        address _padToken,
        uint256 _LaunchPadTSupply,
        uint256 _preSaleTokenSupply,
        uint256 _PadDuration,
        uint _percentagePresalePriceIncrease
    ) public onlyVerifiedAdmin(regId, _padToken) {
        InfinityDaoLaunchPad infinityDaoLaunchPad = new InfinityDaoLaunchPad(
            ProjectAdmin,
            launchPadFee,
            _padToken,
            address(this),
            _LaunchPadTSupply,
            _preSaleTokenSupply,
            _PadDuration,
            msg.sender,
            _percentagePresalePriceIncrease
        );
        uint totalToken = _LaunchPadTSupply + _preSaleTokenSupply;
        bool success = IUSDT(_padToken).transferFrom(
            msg.sender,
            address(infinityDaoLaunchPad),
            totalToken
        );
        require(success, "ERROR TRANSFERING TOKENS");
        launchpads.push(address(infinityDaoLaunchPad));
        LaunchPadRecord[regId].LaunchpadAddress = address(infinityDaoLaunchPad);
        TokenToLaunchPadRecord[_padToken] = address(infinityDaoLaunchPad);
        emit launchpadCreated(
            address(infinityDaoLaunchPad),
            _padToken,
            _PadDuration
        );
    }

    function setLaunchPadFee(uint _amount) public IsAdmin {
        require(_amount != 0, "INVALID PERCENTAGE FEE");
        launchPadFee = _amount;
    }

    function getLaunchPads() public view returns (address[] memory) {
        return launchpads;
    }

    function getLaunchPadAddress(
        address tokenAddress
    ) public view returns (address) {
        return TokenToLaunchPadRecord[tokenAddress];
    }

    function withdrawEth(uint _amount) public IsAdmin {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "TRANSFER ERROR OCCURED");
    }

    receive() external payable {}
}
