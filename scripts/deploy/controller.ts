import {Levels, Log} from '@toreda/log';
import {Time, timeNow} from '@toreda/time';

import "@nomiclabs/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "@cronos-labs/hardhat-cronoscan";

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const {ethers, upgrades} = require('hardhat');

async function main() {
	const log = new Log({
		consoleEnabled: true,
		level: Levels.ALL
	});
	const startTime = timeNow();
	
	// deploy token 
	const tokenContract = await ethers.getContractFactory('Freed');
    const token = await tokenContract.deploy("FREEDOM TOKEN", "FREED", "200000000000000000000000000");
	log.info('Token Contract Deployed Address = ', token.address)
	
	// deploy token vesting contract 
	const vestingContract = await ethers.getContractFactory('TokenVesting');
    const vesting = await vestingContract.deploy(token.address);
	log.info('Token Vesting Contract Deployed Address = ', vesting.address)


	//deploy controller contract
	log.info('Initializing Controller for deployment..');
	const Controller = await ethers.getContractFactory('ControllerFreedom');
	log.info('Deploying Controller Proxy..');
	const controller = await upgrades.deployProxy(Controller, [token.address], {
		initializer: 'initialize'
	});
	log.info('Deploying Controller Contract..');
	const control = await controller.deployed();
	log.info(`Controller Contract = `, control.address)

	//deploy voting contract 
	const votingContract = await ethers.getContractFactory('Voting');
    const voting = await votingContract.deploy(control.address);
	log.info('Voting Contract Deployed Address = ', voting.address)

	const endTime = timeNow();
	log.info(`Controller Contract & Proxy deployed successfully in ${endTime.since(startTime)?.asSeconds()} seconds.`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
