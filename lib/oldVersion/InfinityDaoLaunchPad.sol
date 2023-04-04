// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/IUSDT.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract InfinityDaoLaunchPad {
    using SafeMath for uint256;
    address admin;
    uint totalFees;
    uint[] launchPads;

    // RECORD PAD DETAILS
    struct padData {
        bool isActive;
        bool paidFee;
        address padModerator;
        address padToken;
        uint tokenDecimal;
        uint PTSupply;
        uint PTWithdrawn;
        uint totalPTClaimed;
        uint PEthSupply;
        uint PadExpiry;
        uint EthWithdrawn;
        bool isPresaleClosed;
        uint preSaleTotalSupply;
        uint preSaleEthRaised;
        uint percentageIncrease;
        uint tokenRate;
        address[] participators;
        address[] presaleParticipants;
    }

    struct userData {
        bool claimedOfferedTokens;
        uint userEthOffer;
        uint PTOffered;
    }

    mapping(uint => bool) private isValidId;
    mapping(uint => padData) private padDetails;
    mapping(uint => mapping(address => userData)) private userDetails;

    event launchpadCreated(
        address moderator,
        uint padId,
        address padtoken,
        uint padExpiry
    );

    event DepositedToLaunchPad(uint _padId, address _depositor, uint _ammount);
    event WithdrawLaunchPadToken(uint _padId, address _user, uint _ammount);
    event EthWithdrawn(uint _padId, address _user, uint _ammount);
    event ExpierydateExtended(uint _padId, uint extradays);
    event PresaleLiquidityEmptied(uint _padId, address initiator, uint ammount);
    event newPresale(uint _padId, address user, uint tokenReceived);
    event swappedAfrerWithdrawal(
        uint _padId,
        address _user,
        uint _ammountPTokens,
        uint _ammountEther
    );
    event swappedBeforeWithdrawal(
        uint _padId,
        address _user,
        uint _ammountPTokens,
        uint _ammountEther
    );

    constructor() {
        admin = msg.sender;
    }

    modifier _isValidId(uint Id) {
        if (isValidId[Id] == true) revert("ID ALREADY IN USE");
        _;
    }
    modifier OnlyAdmin() {
        require(msg.sender == admin, "NOT ADMIN");
        _;
    }
    modifier OnlyModerator(uint Id) {
        require(
            msg.sender == padDetails[Id].padModerator,
            "NOT LaunchPad Moderator"
        );
        _;
    }

    function createLaunchPad(
        uint _padId,
        address _padToken,
        uint256 _PTSupply,
        uint256 _preSaleTokenSupply,
        uint256 _PadExpiry,
        uint _percentagePresalePriceIncrease
    ) public _isValidId(_padId) returns (bool success) {
        require(_padToken != address(0));
        require(_PTSupply > 0);
        require(_PadExpiry > 0);
        if (_preSaleTokenSupply > 0) {
            require(_percentagePresalePriceIncrease > 0, "PERCENTAGE TOO LOW");
            require(
                _percentagePresalePriceIncrease <= 100,
                "PERCENTAGE TOO HIGH"
            );
        }
        uint totalToken = _PTSupply + _preSaleTokenSupply;
        success = transferFrom_(IUSDT(_padToken), totalToken, msg.sender);
        recordPadCreation(
            _padToken,
            _PTSupply,
            msg.sender,
            _PadExpiry,
            _padId,
            _preSaleTokenSupply,
            _percentagePresalePriceIncrease
        );
    }

    function recordPadCreation(
        address _padToken,
        uint _PTSupply,
        address _moderator,
        uint _PadExpiry,
        uint _padId,
        uint _preSaleTokenSupply,
        uint _percentageIncrease
    ) internal {
        isValidId[_padId] = true;
        padDetails[_padId].isActive = true;
        padDetails[_padId].paidFee = false;
        padDetails[_padId].padToken = _padToken;
        padDetails[_padId].PTSupply = _PTSupply;
        padDetails[_padId].PTWithdrawn = 0;
        padDetails[_padId].totalPTClaimed = 0;
        padDetails[_padId].PEthSupply = 0;
        padDetails[_padId].PadExpiry = ((_PadExpiry * 1 minutes) +
            block.timestamp);
        padDetails[_padId].padModerator = _moderator;
        padDetails[_padId].EthWithdrawn = 0;
        padDetails[_padId].tokenRate = 0;
        padDetails[_padId].preSaleTotalSupply = _preSaleTokenSupply;
        padDetails[_padId].preSaleEthRaised = 0;
        padDetails[_padId].percentageIncrease = _percentageIncrease;
        padDetails[_padId].tokenDecimal = IUSDT(_padToken).decimals();
        launchPads.push(_padId);
        emit launchpadCreated(
            _moderator,
            _padId,
            _padToken,
            padDetails[_padId].PadExpiry
        );
    }

    function participateWithEth(uint _padId) public payable {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp > endTime) revert("PAD ENDED, CHECK PRESALE");
        require(msg.value > 0, "INVALID TRANSFER AMOUNT");
        padDetails[_padId].participators.push(msg.sender);
        padDetails[_padId].PEthSupply += msg.value;

        userDetails[_padId][msg.sender].claimedOfferedTokens = false;
        userDetails[_padId][msg.sender].userEthOffer += msg.value;
        userDetails[_padId][msg.sender].PTOffered = 0;
        emit DepositedToLaunchPad(_padId, msg.sender, msg.value);
    }

    function withdrawPadToken(uint _padId) public returns (uint) {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        require(
            userDetails[_padId][msg.sender].claimedOfferedTokens == false,
            "ALREADY CLAIMED TOKEN"
        );
        require(
            userDetails[_padId][msg.sender].userEthOffer != 0,
            "DID'NT PARTICIPATE IN LAUNCHPAD"
        );
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("LAUNCHPAD STILL IN PROGRESS");
        address pToken = padDetails[_padId].padToken;
        uint reward = calculateReward(_padId);
        userDetails[_padId][msg.sender].claimedOfferedTokens = true;
        uint PEthSupply = padDetails[_padId].PEthSupply;
        userDetails[_padId][msg.sender].PTOffered = reward;
        padDetails[_padId].totalPTClaimed += reward;
        padDetails[_padId].PTWithdrawn += reward;
        bool success = transfer_(IUSDT(pToken), reward, msg.sender);
        ChangePadState(_padId);
        emit WithdrawLaunchPadToken(_padId, msg.sender, reward);
        return reward;
    }

    function ChangePadState(uint _padId) internal {
        if (padDetails[_padId].isActive == true) {
            padDetails[_padId].isActive == false;
        }
        if (padDetails[_padId].paidFee == false) {
            uint PEthSupply = padDetails[_padId].PEthSupply;
            uint Fee = ((10 * PEthSupply) / 100);
            totalFees += Fee;
            padDetails[_padId].paidFee = true;
        }
        if (padDetails[_padId].tokenRate == 0) {
            calculateTokenPrice(_padId);
        }
    }

    function calculateReward(uint _padId) internal view returns (uint reward) {
        uint totalEth = padDetails[_padId].PEthSupply;
        uint userContribution = userDetails[_padId][msg.sender].userEthOffer;
        uint totalPTokens = padDetails[_padId].PTSupply;
        reward = ((userContribution.mul(totalPTokens)).div(totalEth));
    }

    function calculateTokenPrice(uint _padId) internal {
        uint totalEth = padDetails[_padId].PEthSupply;
        uint totalPTokens = padDetails[_padId].PTSupply;
        uint determiner = 1 ether;
        uint price = ((totalPTokens * determiner) / totalEth);
        padDetails[_padId].tokenRate = price;
    }

    function SwapPadTokenToEthAfterWithdrawal(
        uint _padId,
        uint _ammount
    ) public {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        require(
            userDetails[_padId][msg.sender].claimedOfferedTokens == true,
            "DIDNT PARTICIPATE IN LAUNCHPAD"
        );
        require(
            userDetails[_padId][msg.sender].userEthOffer > 0,
            "DIDNT PARTICIPATE IN LAUNCHPAD"
        );
        require(_ammount > 0, "AMOUNT TOO LOW");
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
        address padToken = padDetails[_padId].padToken;
        transferFrom_(IUSDT(padToken), _ammount, msg.sender);
        uint reward = _ammount;
        uint Eth = (calculateEth(_padId, reward));
        padDetails[_padId].EthWithdrawn += Eth;
        userDetails[_padId][msg.sender].claimedOfferedTokens = true;
        userDetails[_padId][msg.sender].userEthOffer -= Eth;
        // REQUIRE THAT PAD STILL HAS ENOUGH FUNDS
        payable(msg.sender).call{value: Eth}("");
        ChangePadState(_padId);
        emit swappedAfrerWithdrawal(_padId, msg.sender, _ammount, Eth);
    }

    // function SwapPadTokenToEthB4Withdrawal(uint _padId) public {
    //     require(isValidId[_padId] == true, "INVALID PAD ID");
    //     require(
    //         userDetails[_padId][msg.sender].claimedOfferedTokens == false,
    //         "ALREADY CLAIMED TOKEN"
    //     );
    //     require(
    //         userDetails[_padId][msg.sender].userEthOffer != 0,
    //         "DIDNT PARTICIPATE IN LAUNCHPAD"
    //     );
    //     uint endTime = padDetails[_padId].PadExpiry;
    //     if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
    //     uint totalEth = padDetails[_padId].PEthSupply;
    //     uint reward = calculateReward(_padId);
    //     uint Eth = calculateEth(_padId, reward);
    //     require(
    //         Eth < (totalEth - (padDetails[_padId].EthWithdrawn)),
    //         "INSUFFICIENT ETH IN PAD TO COVER REQUEST"
    //     );
    //     padDetails[_padId].EthWithdrawn += Eth;
    //     userDetails[_padId][msg.sender].claimedOfferedTokens = true;
    //     userDetails[_padId][msg.sender].userEthOffer = 0;
    //     payable(msg.sender).call{value: Eth}("");
    //     ChangePadState(_padId);
    //     emit swappedAfrerWithdrawal(_padId, msg.sender, reward, Eth);
    // }

    function calculateEth(
        uint _padId,
        uint reward
    ) internal view returns (uint Eth) {
        uint totalEth = padDetails[_padId].PEthSupply;
        uint totalPTokens = padDetails[_padId].PTSupply;
        Eth = ((totalEth) * reward) / totalPTokens;
    }

    function displayNoOfContributors(
        uint _padId
    ) public view returns (uint contributors) {
        contributors = padDetails[_padId].participators.length;
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

    function withdrawEth(
        uint _padId,
        uint _ammount
    ) public OnlyModerator(_padId) {
        require(_ammount > 0, "AMOUNT TOO LOW");
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
        uint totalEth = padDetails[_padId].PEthSupply;
        uint Fee = ((5 * totalEth) / 100);
        uint pendingDebit = (padDetails[_padId].EthWithdrawn) + Fee;
        require(
            _ammount <= (totalEth - pendingDebit),
            "INSUFFICIENT ETH IN PAD TO COVER REQUEST"
        );
        if (padDetails[_padId].paidFee == false) {
            totalFees += Fee;
            padDetails[_padId].paidFee = true;
            payable(admin).call{value: Fee}("");
        }
        padDetails[_padId].EthWithdrawn += _ammount;
        payable(msg.sender).transfer(_ammount);
        emit EthWithdrawn(_padId, msg.sender, _ammount);
        ChangePadState(_padId);
    }

    function viewEthRaised(uint _padId) public view returns (uint actualBal) {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        uint totalEth = padDetails[_padId].PEthSupply;
        uint Fee = ((5 * (totalEth / 10e18)) / 100);
        uint pendingDebit = (padDetails[_padId].EthWithdrawn) + (Fee * 10e18);
        actualBal = (totalEth - pendingDebit);
    }

    function withdrawPadToken_Admin(
        uint _padId,
        uint _ammount
    ) public OnlyAdmin returns (bool success) {
        require(_ammount > 0, "AMOUNT TOO LOW");
        uint endTime = padDetails[_padId].PadExpiry;
        uint PTSupply = padDetails[_padId].PTSupply;
        address pToken = padDetails[_padId].padToken;
        if (block.timestamp < (endTime + 30 days))
            revert("PAD STILL CLAIMABLE");
        require(
            _ammount < (PTSupply - (padDetails[_padId].PTWithdrawn)),
            "INSUFFICIENT ETH IN PAD TO COVER REQUEST"
        );
        padDetails[_padId].PTWithdrawn += _ammount;
        emit WithdrawLaunchPadToken(_padId, msg.sender, _ammount);
        success = transfer_(IUSDT(pToken), (_ammount), msg.sender);
    }

    function extendLaunchPadExpiry(
        uint _padId,
        uint extraMinutes
    ) public OnlyModerator(_padId) returns (bool success) {
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp > endTime) revert("PAD ALREADY ENDED");
        padDetails[_padId].PadExpiry += (extraMinutes * 1 minutes);
        success = true;
        emit ExpierydateExtended(_padId, extraMinutes);
    }

    function withdrawFees(uint _ammount) public OnlyAdmin {
        require(totalFees >= _ammount, "EXCEEDS OBTAINED FEES");
        (bool success, ) = payable(msg.sender).call{value: _ammount}("");
        require(success, "TRANSFER ERROR");
    }

    function viewFees() public view OnlyAdmin returns (uint tFees) {
        tFees = totalFees;
    }

    function totalLaunchPads() public view returns (uint LaunchPadsNum) {
        LaunchPadsNum = launchPads.length;
    }

    function displayAllLaunchPads()
        public
        view
        returns (uint[] memory LaunchPads)
    {
        LaunchPads = launchPads;
    }

    function participateInPresale(uint _padId) public payable {
        if (padDetails[_padId].isPresaleClosed == true)
            revert("PRESALE SESSION CLOSED");
        require(isValidId[_padId] == true, "INVALID PAD ID");
        uint presaleAmount = padDetails[_padId].preSaleTotalSupply;
        if (presaleAmount == 0) revert("TOKEN DOES NOT SUPPORT PRESALE");
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
        ChangePadState(_padId);
        uint tokenReceived = calculateObtainedToken(_padId, msg.value);
        if (padDetails[_padId].preSaleTotalSupply < tokenReceived)
            revert("INSUFFFICIENT LIQUIDITY");
        padDetails[_padId].preSaleEthRaised += msg.value;
        padDetails[_padId].preSaleTotalSupply -= tokenReceived;
        padDetails[_padId].presaleParticipants.push(msg.sender);
        address token = padDetails[_padId].padToken;
        IUSDT(token).transfer(msg.sender, tokenReceived);
        emit newPresale(_padId, msg.sender, tokenReceived);
    }

    function displayRateFromLaunchPad(
        uint _padId
    ) public view returns (uint rate) {
        rate = padDetails[_padId].tokenRate;
    }

    function withdrawExcessPresaleTokken(
        uint _padId
    ) public OnlyModerator(_padId) returns (bool status) {
        require(
            padDetails[_padId].isPresaleClosed == true,
            "PRESALE NOT ENDED YET"
        );
        address pToken = padDetails[_padId].padToken;
        uint presaleTokenBal = padDetails[_padId].preSaleTotalSupply;
        status = transfer_(IUSDT(pToken), presaleTokenBal, msg.sender);
        emit PresaleLiquidityEmptied(_padId, msg.sender, presaleTokenBal);
    }

    function endPresale(uint _padId) public OnlyModerator(_padId) {
        require(
            padDetails[_padId].isPresaleClosed != true,
            "PRESALE ALREADY ENDED"
        );
        padDetails[_padId].isPresaleClosed = true;
    }

    function viewEthRaisedFromPresale(
        uint _padId
    ) public view returns (uint Eth) {
        Eth = padDetails[_padId].preSaleEthRaised;
    }

    function viewPresaleTokenBalance(
        uint _padId
    ) public view returns (uint tokenBalance) {
        tokenBalance = padDetails[_padId].preSaleTotalSupply;
    }

    function calculateObtainedToken(
        uint _padId,
        uint value
    ) internal view returns (uint ammount) {
        uint rate = padDetails[_padId].tokenRate;
        uint percent = padDetails[_padId].percentageIncrease;
        uint determiner = ((percent * 1 ether) / 100) + 1 ether;
        ammount = (value * rate) / determiner;
    }
}
