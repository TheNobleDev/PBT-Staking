require("@nomiclabs/hardhat-waffle");
// require("@nomicfoundation/hardhat-verify");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      },
  defaultNetwork: "goerli",
  etherscan: {
    apiKey: "KDDGUNQ7G1MUWFI95NJP8CQ1XR6W4TYN43",
  },
  networks: {
    goerli: {
      url: `https://goerli.blockpi.network/v1/rpc/public`,
    },
  },
};
