var MintableToken = artifacts.require('./MintableToken.sol')
var FINMigrate = artifacts.require("./FINMigrate.sol");
var GTXSwap = artifacts.require("./GTXSwap.sol");
var SafeMath = artifacts.require("./SafeMath.sol");
var TimeLock = artifacts.require("./TimeLock.sol")


module.exports = function (deployer) {
    //deploy library
    deployer.deploy(SafeMath);
    //link library
    deployer.link(SafeMath, GTXSwap);
    deployer.link(SafeMath, FINMigrate);
    deployer.link(SafeMath, MintableToken);
    //Deploy GTX Swap Contract
    deployer.deploy(GTXSwap);
    //Deploy FinMigrate Contract
    deployer.deploy(FINMigrate).then(function () {
        console.log("FINMigrate.address", FINMigrate.address)
        //Deploy ERC20 Contract
        deployer.deploy(MintableToken, FINMigrate.address, "Fin Token", "FIN", 18).then(function () {
            console.log("MintableToken.address", MintableToken.address)
        }).then(function() {
            deployer.deploy(TimeLock, MintableToken.address).then(function (){
                console.log("TimeLock contract address", TimeLock.address)
            })
        })
    })
};
