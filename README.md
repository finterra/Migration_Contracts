### Migration Contracts

Compiled contracts for FIN-ERC20, FIN-GTX-SWAP and FIN-MIGRATE required for ICO. Detailed Readme about each contracts are updated inside the contracts folder.

### Prerequisite
    Nodejs v8+
### Installation
1. Install truffle globally
```
npm install -g truffle
```

2. After cloning the project run the below command to install dependencies.
```
npm i
```
3. Compile migrate and test smart contracts
```
truffle compile
truffle migrate
truffle test
```

4. Configure your address in truffle.js to deploy contracts from a specific address
    `from: 'address'`

5. To interact with smart contracts using web3.

    5a. Connect to the network
    ```
    var web3 = new Web3(new Web3.providers.HttpProvider("http://testnet:port"));
    ```
    5b. Create a contract instance to interact with the contract deployed in the {ropsten/mainnet}
    ```
    var contractObj = new web3.eth.Contract(contractABI, contractAddress);
    ```
    where,
    contractABI is found under ./build/contract_name/contract_name.json
    contractAddress address is displayed while deploying the contracts using `truffle migrate --network ropsten`