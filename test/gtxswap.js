var gtxSwap = artifacts.require('./GTXSwap')
require('chai')
    .use(require('chai-as-promised'))
    .should();


contract('GTX SWAP', function (accounts) {
    let gtxInstance;

    before(async function () {
        gtxInstance = await gtxSwap.deployed();
    })



    describe('record update', function () {

        it('Should update 5 FINS in the account', async function () {
            var eventUpdate = gtxInstance.GTXRecordUpdate({ from: 0, toBlock: 'latest' })
            eventUpdate.watch((error, log) => {
                if (!error) {
                    console.log("Watched log", log.args)
                }
            })
            await gtxInstance.recordUpdate(accounts[1], "7000000000000000000", true, { from: accounts[0] })
            var balance = await gtxInstance.recordGet.call(accounts[1])
            console.log("balance", balance)
        })

        it('it should be called only by the contract owner', async function () {
            gtxInstance.recordUpdate(accounts[1], 5000000000000000000, true, { from: accounts[1] }).should.be.rejected;
        })
    })

    // describe('record move', function () {

    // })

})

