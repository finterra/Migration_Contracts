var FINMigrate = artifacts.require("./FINMigrate.sol");
var SafeMath = artifacts.require("./SafeMath.sol");

module.exports = function (deployer) {
    deployer.deploy(SafeMath);
    deployer.link(SafeMath,FINMigrate);
    deployer.deploy(FINMigrate,100);
};