//Import all ABI for testing the contracts
var gtxSwap = artifacts.require('./GTXSwap')
var GTXToken = artifacts.require("./GTXToken");
var GTXMigrate = artifacts.require("./GTXMigrate");
var TimeLock = artifacts.require("./TimeLock");
var GTXICO = artifacts.require("./GTXAuction");

//Connec to
var Web3 = require('web3')
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));


const assert = require("chai").assert;
require("chai")
  .use(require("chai-as-promised"))
  .should();

const multiSigWallet = '0x75fb86fc5663a2fbdee1ddb3862eba4af2a9d1cd'

contract('Tests for GTX Token contracts ', function(accounts) {
    //Global variables
    let gtxSwapIns;
    let gtxTokenIns;
    let gtxMigrateIns;
    let timelockIns;
    let gtxICOIns;

    var swapRate = 200 //2.00 swap rate should be set in 2 decimal points
    var fin = 20000 * 10e18;
    var finWithSwap = 10000 * 10e18;

    //Constant
    const icoAllocation = 50000 * 10e18;
    const owner =  10000 * 10e18;
    const totalSupply = 10000 * 10e19;


    describe('GTX Swap contract', function() {
        before('should return the deployed instance', async function() {
            gtxSwapIns = await gtxSwap.deployed();
        })
        it("Should create some swap records ", async function() {
            gtxSwapIns.setSwapRate(swapRate);
            await gtxSwapIns.recordCreate(accounts[1], finWithSwap, true, { from: accounts[0] })
            await gtxSwapIns.recordCreate(accounts[2], fin, false, { from: accounts[0] })
        })
    })

    describe('GTX Token contract tests', function() {
        before('should deploy gtx token contracts ', async function() {
            gtxTokenIns = await GTXToken.new(totalSupply,"Gallactic","GTX",18);
            gtxMigrateIns = await GTXMigrate.new(gtxTokenIns.address);
            timelockIns = await TimeLock.new(gtxTokenIns.address);
            gtxICOIns = await GTXICO.new(multiSigWallet,222,1234,icoAllocation,45,2,1,gtxTokenIns.address,gtxSwapIns.address)

        })
        it('Should update GTX migrate, timelock and ICO contract address in GTX ERC20', async function() {
            await gtxTokenIns.setMigrationAddress(gtxMigrateIns.address)
            await gtxTokenIns.setTimeLockAddress(timelockIns.address)
            await gtxTokenIns.setICOAddress(gtxICOIns.address)
        })
        it('Should return the balance of the GTX Token contract', async function() {
            var balance = await gtxTokenIns.totalSupply();
            assert.equal(balance.toNumber(),totalSupply,"Total supply and token contract balance should be equal")
        })
        it('Should start migration', async function() {
            await gtxTokenIns.startMigration();
        })
        it('Should reject if already migrated', async function() {
            await gtxTokenIns.startMigration().should.be.rejected;
        })
        it("Should reject migration if it is not the owner", async function() {
            await gtxTokenIns.startMigration({from:accounts[1]}).should.be.rejected;
        })
    })

    describe('GTX ICO contract tests', function() {
        it('should passICOAllocation function from only GTX ICO contract ', async function() {
            var icoAllocatedTokens= await gtxICOIns.getAllocatedTokens()
            assert.equal(icoAllocatedTokens.toNumber(), 90000 * 10e18, "Should be equal to the sum of gtx swap tokens and icoAllocated tokens")


            await gtxICOIns.passAllocation();
            var icoTokens = await gtxTokenIns.balanceOf(gtxICOIns.address)
            assert.equal(icoTokens.toNumber(),90000 * 10e18,"ICO contract should have total ico allocated tokens");

            var ownerTokens = await gtxTokenIns.balanceOf(accounts[0])
            assert.equal(ownerTokens.toNumber(),owner, "Remaining tokens should be allocated to owner")

        })

    })
})
