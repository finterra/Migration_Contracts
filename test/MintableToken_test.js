var MintableToken = artifacts.require('./MintableToken')
var finMigrate = artifacts.require('./FINMigrate')
var standardToken = artifacts.require('./StandardToken')

contract('Mintable Token', function(accounts) {
    var mintableToken;
    before(async function(){
        finContract = await finMigrate.deployed();
        mintableToken = await MintableToken.new(finContract.address,"Fin Token","FIN",18);
        console.log(mintableToken.address)
    })

    
})