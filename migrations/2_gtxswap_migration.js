var GTXSwap = artifacts.require("./GTXSwap.sol");
var SafeMath = artifacts.require("./SafeMath.sol");

module.exports = function (deployer) {
    deployer.deploy(SafeMath);
    deployer.link(SafeMath,GTXSwap);
    deployer.deploy(GTXSwap,1);
};