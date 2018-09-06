pragma solidity 0.4.24;
import "../../GTX-ERC20/contracts/GTXToken.sol";
import "../../FIN-GTX-SWAP/contracts/GTXSwap.sol";

/**
    The MIT License (MIT)

    Copyright (c) 2018 Gallactic

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

// @title GTX Dutch Auction Smart Contract - Distribution of GTX tokens using a modified Dutch Auction.
// @author Ankur Daharwal - <ankur.daharwal@finterra.org>
contract GTXAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Storage
     */

    GTXToken public gtxToken;
    GTXSwap public gtxSwap;
    address public wallet;
    address public owner;
    uint256 public maxTokens;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public totalReceived;
    uint public waitingPeriod;
    uint public etherPrice;
    uint public ceiling;
    uint public floor;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        ClaimingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isWallet() {
        require(wallet != address(0));
        require(msg.sender == wallet);
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && block.number > endBlock + waitingPeriod)
            stage = Stages.ClaimingStarted;
        _;
    }

    /*
     *  GTXAuction Contract Constructor
     */
    // @dev Contract constructor function sets owner
    // @param _multiSigWallet Gallactic ICO Multi Signature Wallet Address
    // @param _etherPrice Ether Price in USD to be set before starting the Auction and stay constant through the ICO
    // @paran _saleEndBlock Last Block of the crowdsale - Initial decision of 345600 (~60 Days)
    // @param _maxTokens Initial decision for 400 Million GTX Tokens to be allocated for ICO
    // @param _auditWatingPeriod Initial decision to have a 15 days waiting period post ICO for Audit before Claiming
    // @param _floor Gallactic ICO Price curve floor price - Initial decision to be 0.25 (USD)
    // @param _ceiling Gallactic ICO Price curve ceiling price - Initial decision to be 5 (USD)
    constructor(address _multiSigWallet, uint _etherPrice, uint256 _saleEndBlock,
        uint256 _maxTokens, uint _auditWaitingPeriod, uint _floor, uint _ceiling)
        public
    {
        require( _multiSigWallet != address(0) );
        require( _saleEndBlock != 0  && _etherPrice != 0 );
        require( _maxTokens != 0 && _auditWaitingPeriod != 0 );
        require( _floor != 0 && _ceiling != 0 );

        /*
        *  Initializing ICO Settings
        */
        maxTokens = _maxTokens;
        waitingPeriod = _auditWaitingPeriod * 1 days;
        etherPrice = _etherPrice;
        endBlock = _saleEndBlock;
        owner = msg.sender;
        wallet = _multiSigWallet;
        floor = _floor;
        ceiling = _ceiling;

        // Set the contract stage to Auction Deployed
        stage = Stages.AuctionDeployed;
    }

    // @dev Setup function sets external contracts' addresses.
    // @param _gtxToken GTX Token Address.
    function setup(address _gtxToken, address _gtxSwap)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        require(_gtxToken != address(0));
        require(_gtxSwap != address(0));

        // Initialize the GTX Token contract
        gtxToken = GTXToken(_gtxToken);

        // Initialize the GTX Swap contract and get total GTX Swap amount
        gtxSwap = GTXSwap(_gtxSwap);
        uint256 gtxSwapTotal = gtxSwap.getTotal();

        // Allocate ICO token amounts (Permissible only to ICO Contract;
        //      Address needs to be set in GTXToken before Auction Setup)
        // gtxToken.passICOAllocation(gtxSwap, maxTokens);

        // Validate allocation amount
        if (gtxToken.balanceOf(this) != maxTokens + gtxSwapTotal )
            revert();
        stage = Stages.AuctionSetUp;
    }

    // @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    // @dev Changes auction price curve variables before auction is started.
    // @param _etherPrice New Ether Price in USD.
    // @param _floor New auction floor price.
    // @param _ceiling New auction ceiling price.
    // @param _saleEndBlock New auction Crowdasale End Block.
    function changeSettings(uint _etherPrice, uint _floor, uint _ceiling, uint _saleEndBlock)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        etherPrice = _etherPrice;
        floor = _floor;
        ceiling = _ceiling;
        endBlock = _saleEndBlock;
    }

    // @dev Calculates current token price.
    // @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.ClaimingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    // @dev Returns correct stage, even if a function with a timedTransitions modifier has not been called yet
    // @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    // @dev Allows to send a bid to the auction.
    // @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        if (receiver == 0)
            receiver = msg.sender;
        amount = msg.value;

        uint maxWei = ( maxTokens / 10**18 ) * calcTokenPrice() - totalReceived;

        // Only Invest Maximum Possible Amount
        if (amount > maxWei) {
            amount = maxWei;
            assert(!receiver.send(msg.value - amount));
        }
        assert( amount != 0 && wallet.send(amount));
        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount)
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        BidSubmission(receiver, amount);
    }

    // @dev Claims tokens for bidder after auction.
    // @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address _receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.ClaimingStarted)
    {
        if (_receiver == address(0))
            _receiver = msg.sender;

        uint tokenCount = bids[_receiver] * 10**18 / finalPrice;
        bids[_receiver] = 0;

        // Check for GTX Swap Tokens
        uint gtxSwapCount = gtxSwap.recordGet(_receiver);

        // Add GTX Swap Tokens to Token Count
        tokenCount += gtxSwapCount;

        gtxToken.transfer(_receiver, tokenCount);
    }

    // @dev Calculates Stop Price for the crowdsale
    // @return Returns Stop Price
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / maxTokens + 1;
    }

    // @dev Calculates token price as per GTX ICO Price Curve
    //      f(x) = ((MAX_PRICE - MIN_PRICE)/etherPrice)*e^(-5x/MAX_BLOCK_NUMBER) + (MIN_PRICE / etherPrice )
    // @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        // Need to re-modify the Price Curve Formula to calculate exponential and use Safe Math

        uint priceFactor = 5*(block.number - startBlock)/endBlock;
        // return ((ceiling-floor)*e(-priceFactor))/etherPrice + floor/etherPrice;
    }

    /*
     *  Finalize Auction (Private function)
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;

        // Check Total Received to be 100 Million USD (in cents) as per initial discussion
        // Need to confirm this condition
        if (totalReceived == 10000000000 / etherPrice )
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();

        // Auction contract transfers all unsold tokens to Gallactic Multi-signature Wallet
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        gtxToken.transfer(wallet, maxTokens - soldTokens);
        endBlock = now;
    }

    /**
    * @dev Used to retrieve GTX ERC20 contract address that this deployment is attatched to
    * @return address - the GTX ERC20 contract address that this deployment is attatched to
    */
    function getERC20() public view returns (address) {
        return gtxToken;
    }
}
