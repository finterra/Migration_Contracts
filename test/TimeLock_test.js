let timeLock = artifacts.require('./TimeLock');
let mintableToken = artifacts.require('./MintableToken')
let finMigrate = artifacts.require('./FINMigrate')

var Web3 = require('web3')
var web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'))

const truffleAssert = require('truffle-assertions');
const assert = require("chai").assert;
require('chai')
    .use(require('chai-as-promised'))
    .should();

const pv = "0x6929676b180d25d2182516811adda52e8b0a18b7052abb8c66fd08608c58990f";

contract('Fin TimeLock', function (accounts) {
    //Global variables
    let finMigrateIns;
    let mintableTokenIns;
    let finTimeLockIns;

    //Fin Record Balance
    record1 = 80 * 10e18
    record2 = 50 * 10e18


    describe('Should approve certain tokens to be spent by TimeLock contracts', async function(){
        before('Should return Fin Migrate, ERC20 and TimeLock instance', async function(){
            finMigrateIns = await finMigrate.deployed();
            await finMigrateIns.setMigrationRate(100)
            mintableTokenIns = await mintableToken.new(finMigrateIns.address, "Fin Token", "FIN", 18);
            finTimeLockIns = await timeLock.new(mintableTokenIns.address)
        })

        it('Should update FinMigrate Records', async function () {
            await finMigrateIns.recordUpdate(accounts[1], record1, true, { from: accounts[0] })
            await finMigrateIns.recordUpdate(accounts[2], record2, true, { from: accounts[0] })
        })

        it('Claim Should mint and transfer tokens to the finMigrate record', async function () {
            //claiming for acocunt1
            //creating message hash including the address and kyc value
            var message = accounts[1]+1;   //here 1 denotes true where the kyc has verified
            var response = web3.eth.accounts.sign(message, pv);
            var msgHash = response.messageHash;
            var v = parseInt(response.v, 16);
            var r = response.r;
            var s = response.s;
            await mintableTokenIns.claim(msgHash,v,r,s,{ from: accounts[1] })
            // claiming for acocunt2
            var message = accounts[2]+1;   //here 1 denotes true where the kyc has verified
            var response = web3.eth.accounts.sign(message, pv);
            var msgHash = response.messageHash;
            var v = parseInt(response.v, 16);
            var r = response.r;
            var s = response.s;
            await mintableTokenIns.claim(msgHash,v,r,s,{ from: accounts[2] })
        })


    })
})