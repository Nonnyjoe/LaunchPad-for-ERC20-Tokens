// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUSDT.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract InfinityDaoLaunchPad {
    event launchpadCreated(
        address moderator,
        address padtoken,
        uint padDuration
    );
    event DepositedToLaunchPad(address _depositor, uint _ammount);
    event LaunchPadTokenWithdrawn(address _user, uint _ammount);
    event LaunchPadTokenWithdrawnByAdmin(address _user, uint _ammount);
    event launchPadTokenSwappedToEther(
        address _user,
        uint tokenQuantity,
        uint Eth
    );
    event EthWithdrawnByAdmin(address admin, uint amount);
    event ExpirydateExtended(uint time);
    event newPresale(address user, uint tokenReceived);
    event PresaleLiquidityEmptied(address admin, uint presaleTotalSupply);

    /**
     * ======================================================================== *
     * --------------------------- ERRORS ------------------------------------- *
     * ======================================================================== *
     */
    error invalidTransferAmount();
    error Pad_ended_check_presale();
    error Pad_ended();
    error Already_Claimed_Token();
    error Didnt_Participate_in_Launchpad();
    error LaunchPad_Still_In_Progress();
    error no_Launch_Pad_RecordFound();
    error Amount_Cannot_be_Zero();
    error Amount_Exceeds_ClaimedTokens();
    error Amount_Exceeds_Returned_Tokens();
    error Amount_Exceeds_Balance();
    error Presale_Not_Open_Yet();
    error No_Presale_Liquidity();
    error Presale_Closed();
    error Insufficient_Presale_Liquidity();
    error Presale_Must_Be_Closed();

    modifier OnlyModerator() {
        require(msg.sender == padModerator, "NOT LaunchPad Moderator");
        _;
    }

    // GENERAL RECORD
    address feeReceiver;
    address contractOverseer;
    uint totalFees;
    uint256 TokenRateFromPad;
    uint launchPadFee;
    bool hasPaidFees;

    // LAUNCHPAD  RECORD
    bool isActive;
    address padToken;
    address padModerator;

    // uint256 padTokenWithdrawn;
    uint256 LaunchPadTSupply;
    uint256 totalPadTokensClaimed;
    uint256 EthRaisedByPad;
    uint256 PadDuration;
    uint256 EthWithdrawnFromPad;
    address[] launchPadParticipators;
    uint256 returnedTokens;

    // PRESALE RECORDS
    bool isPresaleClosed;
    uint256 presaleTotalSupply;
    uint256 EthRaisedFromPresale;
    uint256 percentagePriceIncrease;
    address[] presaleParticipants;

    // USER RECORDS
    mapping(address => bool) hasClaimedLaunchpadTokens;
    mapping(address => uint) userEthDepositedToLaunchpad;
    mapping(address => uint) launchPadTokensOwned;

    using SafeMath for uint256;

    constructor(
        address _contractOverseer,
        uint _launchPadFee,
        address _padToken,
        address _feeReceiver,
        uint256 _LaunchPadTSupply,
        uint256 _preSaleTokenSupply,
        uint256 _PadDuration,
        address _moderator,
        uint _percentagePresalePriceIncrease
    ) {
        createLaunchPad(
            _contractOverseer,
            _launchPadFee,
            _padToken,
            _feeReceiver,
            _LaunchPadTSupply,
            _preSaleTokenSupply,
            _PadDuration,
            _moderator,
            _percentagePresalePriceIncrease
        );
    }

    function createLaunchPad(
        address _contractOverseer,
        uint _launchPadFee,
        address _padToken,
        address _feeReceiver,
        uint256 _LaunchPadTSupply,
        uint256 _preSaleTokenSupply,
        uint256 _PadDuration,
        address _moderator,
        uint _percentagePresalePriceIncrease
    ) internal {
        require(_padToken != address(0));
        require(_LaunchPadTSupply > 0);
        require(_PadDuration > 0);
        if (_preSaleTokenSupply > 0) {
            require(_percentagePresalePriceIncrease > 0, "PERCENTAGE TOO LOW");
            require(
                _percentagePresalePriceIncrease <= 100,
                "PERCENTAGE TOO HIGH"
            );
        }
        recordPadCreation(
            _contractOverseer,
            _launchPadFee,
            _feeReceiver,
            _padToken,
            _LaunchPadTSupply,
            _moderator,
            _PadDuration,
            _preSaleTokenSupply,
            _percentagePresalePriceIncrease
        );
    }

    function participateWithEth() public payable {
        if (block.timestamp > PadDuration) revert Pad_ended_check_presale();
        if (msg.value == 0) revert invalidTransferAmount();
        launchPadParticipators.push(msg.sender);
        EthRaisedByPad += msg.value;
        userEthDepositedToLaunchpad[msg.sender] += msg.value;
        emit DepositedToLaunchPad(msg.sender, msg.value);
    }

    function WithdrawLaunchPadToken() public {
        if (hasClaimedLaunchpadTokens[msg.sender] == true)
            revert Already_Claimed_Token();
        if (userEthDepositedToLaunchpad[msg.sender] == 0)
            revert Didnt_Participate_in_Launchpad();
        if (block.timestamp < PadDuration) revert LaunchPad_Still_In_Progress();
        uint reward = calculateReward();
        hasClaimedLaunchpadTokens[msg.sender] = true;
        totalPadTokensClaimed += reward;
        bool success = transfer_(IUSDT(padToken), reward, msg.sender);
        ChangePadState();
        emit LaunchPadTokenWithdrawn(msg.sender, reward);
    }

    function swapLaunchPadTokenToEther(uint _amount) public {
        if (hasClaimedLaunchpadTokens[msg.sender] == false)
            revert no_Launch_Pad_RecordFound();
        if (_amount == 0) revert Amount_Cannot_be_Zero();
        if (_amount > launchPadTokensOwned[msg.sender])
            revert Amount_Exceeds_ClaimedTokens();
        launchPadTokensOwned[msg.sender] = launchPadTokensOwned[msg.sender].sub(
            _amount
        );
        transferFrom_(IUSDT(padToken), _amount, msg.sender);
        uint Eth = (calculateEth(_amount));
        EthWithdrawnFromPad = EthWithdrawnFromPad.add(Eth);
        returnedTokens = returnedTokens.add(_amount);
        EthRaisedByPad = EthRaisedByPad.sub(Eth);
        userEthDepositedToLaunchpad[msg.sender] = (
            userEthDepositedToLaunchpad[msg.sender]
        ).sub(Eth);
        (bool success, ) = payable(msg.sender).call{value: Eth}("");
        require(success, "ETHER TRANSFER FAILED");
        emit launchPadTokenSwappedToEther(msg.sender, _amount, Eth);
    }

    function displayNoOfLaunchPadContributors()
        public
        view
        returns (uint contributors)
    {
        contributors = launchPadParticipators.length;
    }

    function displayLaunchPadContributors()
        public
        view
        returns (address[] memory)
    {
        return launchPadParticipators;
    }

    function WithdrawEther(uint _amount) public OnlyModerator {
        if (_amount == 0) revert invalidTransferAmount();
        if (block.timestamp < PadDuration) revert LaunchPad_Still_In_Progress();
        ChangePadState();
        uint PendingDebit = EthWithdrawnFromPad + totalFees;
        if (_amount > ((EthRaisedByPad + EthRaisedFromPresale) - PendingDebit))
            revert Amount_Exceeds_Balance();
        uint paidFee;
        if (totalFees > 0) {
            (bool success, ) = payable(feeReceiver).call{value: totalFees}("");
            require(success, "TRANSFER FAILED");
            paidFee = totalFees;
            totalFees = 0;
        }
        EthWithdrawnFromPad = EthWithdrawnFromPad.add(totalFees + _amount);
        payable(msg.sender).transfer(_amount);
        emit EthWithdrawnByAdmin(msg.sender, _amount);
    }

    function viewEthRaisedFromLaunchPad() public view returns (uint Raised) {
        Raised = EthRaisedByPad;
    }

    function viewEthRaisedFromPreSale() public view returns (uint Raised) {
        Raised = EthRaisedFromPresale;
    }

    function calculateEth(uint reward) internal view returns (uint Eth) {
        Eth = ((EthRaisedFromPresale) * reward) / presaleTotalSupply;
    }

    function withdrawPadToken_Admin(uint _amount) public OnlyModerator {
        if (_amount == 0) revert Amount_Cannot_be_Zero();
        if (_amount > (returnedTokens)) revert Amount_Exceeds_Returned_Tokens();
        returnedTokens = returnedTokens.sub(_amount);
        bool success = transfer_(IUSDT(padToken), _amount, msg.sender);
        emit LaunchPadTokenWithdrawnByAdmin(msg.sender, _amount);
    }

    function extendLaunchPadExpiry(
        uint extraMinutes
    ) public OnlyModerator returns (bool success) {
        if (block.timestamp > PadDuration) revert Pad_ended();
        PadDuration = PadDuration.add((extraMinutes * 1 minutes));
        success = true;
        emit ExpirydateExtended(extraMinutes);
    }

    function participateInPresale() public payable {
        require(block.timestamp > PadDuration, "LAUNCHPAD STILL IN PROGRESS");
        ChangePadState();
        if (isActive == true) revert Presale_Not_Open_Yet();
        if (presaleTotalSupply == 0) revert No_Presale_Liquidity();
        if (isPresaleClosed == true) revert Presale_Closed();
        uint tokenReceived = calculateObtainedToken(msg.value);
        if (tokenReceived > presaleTotalSupply)
            revert Insufficient_Presale_Liquidity();
        presaleTotalSupply = presaleTotalSupply.sub(tokenReceived);
        EthRaisedFromPresale = EthRaisedFromPresale.add(msg.value);
        presaleParticipants.push(msg.sender);
        bool success = IUSDT(padToken).transfer(msg.sender, tokenReceived);
        require(success, "ERROR TRANSFERING TOKENS");
        emit newPresale(msg.sender, tokenReceived);
    }

    function withdrawExcessPresaleTokken() public OnlyModerator {
        if (isPresaleClosed == false) revert Presale_Must_Be_Closed();
        bool status = transfer_(
            IUSDT(padToken),
            presaleTotalSupply,
            msg.sender
        );
        require(status, "ERROR TRANSFERING TOKENS");
        emit PresaleLiquidityEmptied(msg.sender, presaleTotalSupply);
    }

    function endPresale() public OnlyModerator {
        if (isPresaleClosed == true) revert Presale_Closed();
        isPresaleClosed = true;
    }

    function viewEthRaisedFromPresale() public view returns (uint Eth) {
        Eth = EthRaisedFromPresale;
    }

    function viewPresaleTokenBalance() public view returns (uint tokenBalance) {
        tokenBalance = presaleTotalSupply;
    }

    function calculateObtainedToken(
        uint value
    ) internal view returns (uint ammount) {
        uint determiner = ((percentagePriceIncrease * 1 ether) / 100) + 1 ether;
        ammount = (value * TokenRateFromPad) / determiner;
    }

    function ChangePadState() internal {
        if (isActive == true) {
            isActive = false;
        }
        if (hasPaidFees == false) {
            uint Fee = ((launchPadFee * EthRaisedByPad) / 100);
            totalFees = Fee;
            hasPaidFees = true;
        }
        if (TokenRateFromPad == 0) {
            calculateTokenPrice();
        }
    }

    function displayPresaleParticipants()
        public
        view
        returns (address[] memory)
    {
        return presaleParticipants;
    }

    function DisplayRateFromLaunchPad() public view returns (uint rate) {
        rate = TokenRateFromPad;
    }

    function calculateTokenPrice() internal {
        uint determiner = 1 ether;
        uint price = ((LaunchPadTSupply * determiner) / EthRaisedByPad);
        TokenRateFromPad = price;
    }

    function transfer_(
        IUSDT _token,
        uint _ammount,
        address _to
    ) internal returns (bool) {
        bool Status_ = _token.transfer(_to, uint(_ammount));
        require(Status_, "TRANSFER FAILED");
        return Status_;
    }

    function calculateReward() internal returns (uint256 reward) {
        uint contribution = userEthDepositedToLaunchpad[msg.sender];
        reward = ((contribution.mul(LaunchPadTSupply)).div(EthRaisedByPad));
        launchPadTokensOwned[msg.sender] = reward;
    }

    function recordPadCreation(
        address _contractOverseer,
        uint _launchPadFee,
        address _feeReceiver,
        address _padToken,
        uint _LaunchPadTSupply,
        address _moderator,
        uint _PadDuration,
        uint _preSaleTokenSupply,
        uint _percentageIncrease
    ) internal {
        contractOverseer = _contractOverseer;
        launchPadFee = _launchPadFee;
        isActive = true;
        padToken = _padToken;
        LaunchPadTSupply = _LaunchPadTSupply;
        PadDuration = ((_PadDuration * 1 minutes) + block.timestamp);
        padModerator = _moderator;
        presaleTotalSupply = _preSaleTokenSupply;
        percentagePriceIncrease = _percentageIncrease;
        feeReceiver = _feeReceiver;
        emit launchpadCreated(_moderator, _padToken, PadDuration);
    }

    function transferFrom_(
        IUSDT _token,
        uint _ammount,
        address _from
    ) internal returns (bool) {
        bool Status_ = _token.transferFrom(
            _from,
            address(this),
            uint(_ammount)
        );
        require(Status_, "TRANSFER FAILED");
        return Status_;
    }
}
