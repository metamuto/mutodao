import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-jest-plugin";
import "@openzeppelin/hardhat-upgrades";
import "solidity-docgen";
import "@nomiclabs/hardhat-solpp";

import * as dotenv from "dotenv";

import {HardhatUserConfig, task} from "hardhat/config";

// solidity-coverage does not currently support typescript and does
// not work as an import due to the way it injects things into the
// environment. Must use require call (for now).
require("solidity-coverage");

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

const optimizer = {
	enabled: true,
	runs: 10
};

/**
 * Hardhat configuration used in build and testing.
 */
const config: HardhatUserConfig = {
	/**
	 * Main Hardhat paths.
	 */
	paths: {
		artifacts: "./dist/artifacts",
		tests: "./tests",
		root: ".",
		sources: "./contracts"
	},
	/**
	 * Plugin Settings: @nomiclabs/hardhat-solpp
	 * Makes the solidity preprocessor plugin available inside hardhat. Flattens source files
	 * and inlines naked imports. Simplifies contract scanning and reduces size.
	 */
	solpp: {},
	/**
	 * Plugin Settings: solidity-docgen
	 * Settings for automatic documentation generation provided by
	 */
	docgen: {
		"outputDir": "./docs",
		"pages": "items",
		"collapseNewlines": true,
		"theme": "markdown"
	},
	/**
	 * Solidity Compiler Settings
	 */
	solidity: {
		/** We rely on features from newer Solidity versions. */
		version: "0.8.4",
		settings: {
			optimizer: optimizer
		}
	},
	/**
	 * Individual Network Settings
	 */
	
	networks: {
		rinkeby: {
			chainId: 4,
			url: process.env.RINKEBY_URL || "",
			accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			blockGasLimit: 10000000000000 // whatever you want here
		},
		ropsten: {
			chainId: 3,
			url: process.env.ROPSTEN_URL || "",
			accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			blockGasLimit: 10000000000000 // whatever you want here
		},
		bsctest: {
			url: process.env.BSCTEST_URL || "", 
			chainId: 97,
			gasPrice: 20000000000,
			accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
		  },
		  goerli: {
			url: process.env.GOERLI_URL || "",
			chainId: 5,
			gasPrice: 10000000000,
			accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			blockGasLimit: 10000000000000
		  },
	  
	},
	// gasReporter: {
	// 	enabled: process.env.REPORT_GAS !== undefined,
	// 	currency: "USD"
	// },
	etherscan: {
		apiKey:{
			goerli: process.env.ETHERSCAN_API_KEY,
			ropsten: process.env.ETHERSCAN_API_KEY,
			rinkeby: process.env.ETHERSCAN_API_KEY,
			bscTestnet: process.env.BSCSCAN_API_KEY
		}		
	}
};

export default config;
