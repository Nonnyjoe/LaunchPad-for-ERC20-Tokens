// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import "./IUSDT.sol";

contract LaunchPad {
    AggregatorV3Interface internal priceFeedEth;
    address admin;
    int EthDecimals = 1e8;

    // RECORD PAD DETAILS
    struct padData {
        bool isActive;
        address padToken;
        uint PTSupply;
        uint totalPTClaimed;
        uint PEthSupply;
        uint PadExpiry;
        uint padModerator;
        address[] participators;
    }

    struct userData {
        bool claimedOfferedTokens;
        uint userEthOffer;
        uint PTOffered;
    }

    mapping(uint => bool) private isValidId;
    mapping(uint => padData) private padDetails;
    mapping(uint => mapping(address => userData)) private userDetails;

    constructor(address _padToken, uint256 _PTSupply, uint256 _PadExpiry) {
        priceFeedEth = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
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

    function createLaunchPad(
        uint _padId,
        address _padToken,
        uint256 _PTSupply,
        uint256 _PadExpiry
    ) public _isValidId(_padId) {
        require(_padToken != address(0));
        require(_PTSupply > 0);
        require(_PadExpiry > 0);
        transferFrom_(_padToken, _PTSupply, msg.sender);
        recordPadCreation(_padToken, _PTSupply, msg.sender, _PadExpiry, _padId);
    }

    function recordPadCreation(
        address _padToken,
        uint _PTSupply,
        address _moderator,
        uint _PadExpiry,
        uint _padId
    ) internal {
        isValidId[_padId] = true;
        padDetails[_padId].isActive = true;
        padDetails[_padId].padToken = _padToken;
        padDetails[_padId].PTSupply = _PTSupply;
        padDetails[_padId].totalPTClaimed = 0;
        padDetails[_padId].PEthSupply = 0;
        padDetails[_padId].PadExpiry = ((_PadExpiry * 86400) + block.timestamp);
        padDetails[_padId].padModerator = _moderator;
        padDetails[_padId].participators = [];
    }

    function participateWithEth(uint _padId) public payable {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp > endTime) revert("PAD ENDED");
        require(msg.value > 0, "INVALID TRANSFER AMOUNT");
        padDetails[_padId].participators.push(msg.sender);
        padDetails[_padId].PEthSupply += msg.value;

        userDetails[_padId][msg.sender].claimedOfferedTokens = false;
        userDetails[_padId][msg.sender].userEthOffer = msg.value;
        userDetails[_padId][msg.sender].PTOffered = 0;
    }

    function withdrawPadToken(uint _padId) public {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        require(
            userDetails[_padId][msg.sender].claimedOfferedTokens == false,
            "ALREADY CLAIMED TOKEN"
        );
        require(
            userDetails[_padId][msg.sender].userEthOffer != 0,
            "DIDNT PARTICIPATE IN LAUNCHPAD"
        );
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
        address pToken = padDetails[_padId].padToken;
        uint reward = calculateReward(_padId);
        userDetails[_padId][msg.sender].claimedOfferedTokens = true;
        userDetails[_padId][msg.sender].PTOffered = reward;
        padDetails[_padId].totalPTClaimed -= reward;
        transfer_(pToken, reward, msg.sender);
    }

    function calculateReward(uint _padId) internal view returns (uint reward) {
        uint totalEth = padDetails[_padId].PEthSupply;
        uint userContribution = userDetails[_padId][msg.sender].userEthOffer;
        uint totalPTokens = padDetails[_padId].PTSupply;
        reward = ((userContribution / (totalEth / 1e18)) * totalPTokens);
    }

    function SwapPadTokenToEthB4Withdrawal(uint _padId) public {
        require(isValidId[_padId] == true, "INVALID PAD ID");
        require(
            userDetails[_padId][msg.sender].claimedOfferedTokens == false,
            "ALREADY CLAIMED TOKEN"
        );
        require(
            userDetails[_padId][msg.sender].userEthOffer != 0,
            "DIDNT PARTICIPATE IN LAUNCHPAD"
        );
        uint endTime = padDetails[_padId].PadExpiry;
        if (block.timestamp < endTime) revert("PAD STILL IN PROGRESS");
        uint totalEth = padDetails[_padId].PEthSupply;
        uint Eth = calculateEth(_padId);
        require(
            (Eth * 1e18) < totalEth,
            "INSUFFICIENT ETH IN PAD TO COVER REQUEST"
        );
        payable(msg.sender).transfer(uint(Eth * 1e18));
        totalEth = totalEth - uint(_ammount);
    }

    function calculateEth(uint _padId) internal view returns (uint Eth) {
        uint totalEth = padDetails[_padId].PEthSupply;
        uint userContribution = userDetails[_padId][msg.sender].userEthOffer;
        uint totalPTokens = padDetails[_padId].PTSupply;
        uint reward = calculateReward(_padId);
        Eth = ((totalEth / 1e18) * reward) / totalPTokens;
    }

    function displayLiquidityProviders()
        public
        view
        returns (address[] memory)
    {
        address[] memory providers = token2LiquidityProvider[address(padToken)];
    }

    function swapEthTopadToken() public payable {
        swappEth(msg.value, priceFeedEth, padToken, totalpadToken);
    }

    function swappadTokenToEth(uint amountOfpadToken) public {
        swapToken2Eth(amountOfpadToken, priceFeedEth, padToken);
    }

    function getLatestPrice_(
        AggregatorV3Interface _pricefeed
    ) internal view returns (int) {
        (, int price, , , ) = _pricefeed.latestRoundData();
        return (price);
    }

    function transfer_(
        IUSDT _token,
        int _ammount,
        address _to
    ) internal returns (bool) {
        bool Status_ = _token.transfer(_to, uint(_ammount));
        require(Status_, "TRANSFER FAILED");
        return Status_;
    }

    function transferFrom_(
        IUSDT _token,
        int _ammount,
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

    function TransferEth(
        uint _amount,
        address payable _sender
    ) internal returns (bool) {
        payable(_sender).transfer(_amount / 1e18);
        return true;
    }

    function PriceCheck_(int price) internal pure {
        require(price > 0, "PRICE FEED CURRENTLY UNAVAILABLE");
    }
}
