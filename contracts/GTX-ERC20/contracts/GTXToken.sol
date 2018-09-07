pragma solidity ^0.4.24;
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

/**
 * This is an ERC-20 standard contract used for the Gallactic ICO and Gallactic Network token migration
 * GTXSwap is used here to fetch the total claimable GTX Tokens as per the FIN points swapped for GTX Tokens
*/
import "./StandardToken.sol";
import "../../FIN-GTX-SWAP/contracts/GTXSwap.sol";
import "../../GTX-ERC20-MIGRATE/contracts/GTXERC20Migrate.sol";
import "../../GTX-ICO/contracts/GTXAuction.sol";
import "../../TIMELOCK/contracts/TimeLock.sol";

    /**
     * @title GTXToken
     * @author Ankur Daharwal <ankur.daharwal@finterra.org>
     * @dev An ERC20 Token Contract based on the ERC20 StandardToken
     * with permissions given to Migration and ICO contracts for certain methods
     * This ERC20 Token is used for the GTX Blockchain ICO and token migration.
    */
contract GTXToken is StandardToken, Ownable{
    event SetMigrationAddress(address GTXERC20MigrateAddress);
    event SetICOAddress(address GTXICOContractAddress);
    event SetTimeLockAddress(address _timeLockAddress);
    event Migrated(address indexed account, uint256 amount);
    event MigrationStarted();


    //global variables
    uint256 totalGTXSwap;
    uint256 icoAllocation;

    // var for storing the the GTXRC20Migrate contract deployment address (for migration to the GALLACTIC network)
    GTXMigrate gtxMigrationContract;
    GTXAuction  gtxICOContract;

    /**
     * @dev Modifier for only GTX migration contract address
    */
    modifier onlyMigrate {
        require(gtxMigrationContract != address(0));
        require(msg.sender == address(gtxMigrationContract));
        _;
    }

    /**
     * @dev Modifier for only gallactic ICO contract address
    */
    modifier onlyICO {
        require(gtxICOContract != address(0));
        require(msg.sender == address(gtxICOContract));
        _;
    }

    /**
     * @dev Constructor to pass the GTX ERC20 arguments
     * @param _totalSupply the total token supply (Initial Proposal is 1,000,000,000)
     * @param _name ERC20 Token Name (Gallactic Token)
     * @param _symbol ERC20 Token Symbol (GTX)
     * @param _decimals ERC20 Token Decimal precision value (18)
    */
    constructor(uint256 _totalSupply, string _name, string _symbol, uint8 _decimals)
    StandardToken(_name,_symbol,_decimals) public {
        totalSupply_ = _totalSupply;
        emit Transfer(this, owner, totalSupply_);
    }

    /**
    * @dev Function to set the migration contract address
    * @return True if the operation was successful.
    */
    function setMigrationAddress(GTXMigrate _gtxMigrateContract) public onlyOwner returns (bool) {
        // check that this GTX ERC20 deployment is the migration contract's attached ERC20 token
        require(_gtxMigrateContract.getERC20() == address(this));

        gtxMigrationContract = _gtxMigrateContract;
        emit SetMigrationAddress(_gtxMigrateContract);
        return true;
    }

    /**
    * @dev Function to set the ICO contract address
    * @return True if the operation was successful.
    */
    function setICOAddress(GTXAuction _gtxICOContract) public onlyOwner returns (bool) {
        // check that this GTX ERC20 deployment is the ICO contract's attached ERC20 token
        require(_gtxICOContract.getERC20() == address(this));

        gtxICOContract = _gtxICOContract;
        emit SetICOAddress(_gtxICOContract);
        return true;
    }

    /**
    * @dev Function to set the TimeLock contract address
    * @return True if the operation was successful.
    */
    function setTimeLockAddress(TimeLock _timeLockContract) public onlyOwner returns (bool) {
        // check that this FIN ERC20 deployment is the timelock contract's attached ERC20 token
        require(_timeLockContract.getERC20() == address(this));

        timeLockContract = _timeLockContract;
        emit SetTimeLockAddress(_timeLockContract);
        return true;
    }

    /**
    * @dev Function to start the migration period
    * @return True if the operation was successful.
    */
    function startMigration() public onlyOwner returns (bool) {
        require(migrationStart == false);
        // check that the FIN migration contract address is set
        require(gtxMigrationContract != address(0));
        // check that the GTX ICO contract address is set
        require(gtxICOContract != address(0));
        // check that the TimeLock contract address is set
        require(timeLockContract != address(0));

        migrationStart = true;
        emit MigrationStarted();

        return true;
    }

    /**
     * @dev Function to pass the ICO Allocation to the ICO Contract Address
     * @dev modifier onlyICO Permissioned only to the Gallactic ICO Contract Owner
     * @param _icoAllocation The GTX ICO Allocation Amount (Initial Proposal 400,000,000 tokens)
    */

    function passICOAllocation(uint256 _icoAllocation) public onlyICO {
        require(_icoAllocation <= totalSupply_, "totalICOAllocation should always be less than totalSuppky");
        balances[gtxICOContract] = _icoAllocation;

        uint256 remainingTokens = totalSupply_.sub(_icoAllocation);
        balances[owner] = remainingTokens;
    }

    /**
     * @dev Function to modify the GTX ERC-20 balance in compliance with migration to GTX ERC-777 on the GALLACTIC Network
     *      - called by the GTX-ERC20-MIGRATE GTXERC20Migrate.sol Migration Contract to record the amount of tokens to be migrated
     * @dev modifier onlyMigrate - Permissioned only to the deployed GTXERC20Migrate.sol Migration Contract
     * @param _account The Ethereum account which holds some GTX ERC20 balance to be migrated to Gallactic
     * @param _amount The amount of GTX ERC20 to be migrated
    */
    function migrateTransfer(address _account, uint256 _amount) onlyMigrate public returns (uint256) {
        require(migrationStart == true);
        uint256 userBalance = balanceOf(_account);
        require(userBalance >= _amount);

        emit Migrated(_account, _amount);
        balances[_account] = balances[_account].sub(_amount);
        return _amount;
    }
}