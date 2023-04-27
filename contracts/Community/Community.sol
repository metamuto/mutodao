//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Status for community.
 * @notice Community Status for each community which limits available actions.
 */
enum CommunityStatus {
	ACTIVE,
	ABANDONED,
	SUSPENDED,
	INACTIVE,
	NOT_FOUND
}

/**
 * @title Community group - in which members will come
 * @notice
 */
struct Group { 
	uint256 id;
	string name;
	string[] members; //member address
	uint256[] proposalCreation;
	uint256[] voting;
}

/**
 * @title  
 * @notice is member of community of response 
 */
struct MemberOfCommRes {
	bool isMember;
	uint256 groupId;
	uint256[] proposalCreation;
	uint256[] voting;
}

/**
 * @title Community data format
 * @notice
 */
struct Community {
	uint256 id;
	CommunityStatus status;
	// uint256 [] GroupIds;
	uint256 createBlock;
	uint256 createTimestamp;
	address creator;

	// 	will add these later on
	string name;
	string purpose;
	string[] links;
	string cover;
	string logo;
	string legalStatus;
	string legalDocs;
	string bondsToCreateProposal;
	string timeBeforeProposalExpires;
	string bondsToClaimBounty;
	string timeToUnclaimBounty;
	uint balance;
}