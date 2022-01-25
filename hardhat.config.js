require("@nomiclabs/hardhat-waffle");
const fs = require("fs")
const privateKey = fs.readFileSync(".secret").toString()
const projectId = "855d9d46f40b46829d489b7024e91d4a"

module.exports = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      // url: `https://polygon-mumbai.infura.io/v3/${projectId}`,
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: [privateKey]
    },
    mainnet: {
      url: `https://polygon-mainnet.infura.io/v3/${projectId}`,
      accounts: [privateKey]
    },
  },
  solidity: "0.8.4",
};
