module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      host: "54.95.9.122",
      port: 8545,
      network_id: 3,
      gas: 4700000,
      from: '0xabd362d60e32e5c9ec40cfddaefa8d0b91384771', // Default ropsten account to deploy contracts
    }
  }
};

