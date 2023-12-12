/** @type import('hardhat/config').HardhatUserConfig */
require('@typechain/hardhat');

module.exports = {
  typechain: {
    outDir: 'typechain',
    target: 'web3-v1',
    alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    externalArtifacts: ['externalArtifacts/*.json'], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
    dontOverrideCompile: false // defaults to false
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        }
      }
    ]
  },
};
