//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Group} from "./Community.sol";

/**
 * @notice Data structure for Community-based polls and proposals.
 */
struct CommunityPoll {
	uint256 id;
	address creator;
	PollStatus status;
	uint256 _type; //1- [amount, targetAcc], 2- [bountyAmount, availableClaims, daystoComplete], 3- [proposedDaoName], 4- [proposedPurpose], 5- [links], 6- [proposedCover, proposedLogo], 7- [proposedLegalStatus, proposedLegalDocs], 8- [bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty] , 9- [newGroupName, intialMemberAccount], 10- [targetGroupName, memberToAdd], 11- [targetGroupName, memberToRemove], 12-[], 13- [contractAddrFnCall, fnCallName, fnCallAbi]
	ProposeChanges proposedChanges;
	uint256 startTimeStamps;
	uint256 endTimeStamps;
	bool result; // false - if proposal lose voting  && true - if proposal won voting 
}

// { value: 1, label: 'Propose a Transfer', fields: [{name: "Amount", val: "amount"}, {name: "Target Account", val: "targetAcc"},] }, //amount, targetAcc
// { value: 2, label: 'Propose to Create Bounty', fields: [{name: "Bounty Amount", val: "bountyAmount"}, {name: "Available Claim Amount", val: "availableClaims"}, {name: "Days to complete", val: "daystoComplete"}]}, // bountyAmount, availableClaims, daystoComplete,
// { value: 3, label: 'Propose to Change DAO Name', fields: [{name: "Proposed DAO Name", val: "proposedDaoName"}] }, // proposedDaoName,
// { value: 4, label: 'Propose to Change Dao Purpose', fields: [{name: "Proposed Purpose", val: "proposedPurpose"}] }, // proposedPurpose
// { value: 5, label: 'Propose to Change Dao Links', fields: [{name: "Proposed Links", val: "links"}] }, // links
// { value: 6, label: 'Propose to Change Dao Flag and Logo', fields: [{name: "Proposed Cover Image", val: "proposedCover"},{name: "Proposed Logo", val: "proposedLogo"}]}, // proposedCover, proposedLogo
// { value: 7, label: 'Propose to Change DAO Legal Status and Doc', fields: [{name: "Proposed Legal Status", val: "proposedLegalStatus"},{name: "Proposed Legal Docs", val: "proposedLegalDocs"}]  }, // proposedLegalStatus, proposedLegalDocs
// { value: 8, label: 'Propose to Change Bonds and Deadlines', fields: [{name: "Bonds", val: "bondsToCreateProposal"},{name: "Expiry", val: "timeBeforeProposalExpires"}, {name: "Bonds to claim bounty", val: "bondsToClaimBounty"}, {name: "Time to UnClaim Bounty", val: "timeToUnclaimBounty"}] }, // bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty
// { value: 9, label: 'Propose to Create a Group', fields: [{name: "New Group Name", val: "newGroupName"}, {name: "Initial Member Account", val: "intialMemberAccount"},]  }, // newGroupName, intialMemberAccount,
// { value: 10, label: 'Propose to Add Member from Group', fields: [{name: "Target Group Name", val: "targetGroupName"}, {name: "Member To Add ", val: "memberToAdd"}]}, // targetGroupName, memberToAdd

// okay
// { value: 11, label: 'Propose to Remove Member from Group', fields: [{name: "Target Group Name", val: "targetGroupName"}, {name: "Member To Remove", val: "memberToRemove"}] }, // targetGroupName, memberToRemove
// { value: 12, label: 'Propose a Poll', fields: [] }, // with this type basic name and description would come
// { value: 13, label:  'Custom Function Call', fields: [{name: "Contract Address", val: "contractAddrFnCall"}, {name: "Function", val: "fnCallName"}, {name: "JSON ABI", val: "fnCallAbi"}]  } // contractAddrFnCall, fnCallName, fnCallAbi

// amount, targetAcc, bountyAmount, availableClaims, daystoComplete, proposedDaoName, proposedPurpose, links,proposedCover, proposedLogo, proposedLegalStatus, proposedLegalDocs, bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty, newGroupName, intialMemberAccount, targetGroupName, memberToAdd, memberToRemove, contractAddrFnCall, fnCallName, fnCallAbi
struct ProposeChanges {
	uint256 amount;
	address targetAcc;
	uint256 bountyAmount;
	uint256 availableClaims;
	uint256 daystoComplete; // after these day nobody can claim whatever the situation is
	uint256 alreadyClaimed; //how many claimed are done
	string proposedDaoName;
	string proposedPurpose;
	string[] links;
	string proposedCover;
	string proposedLogo;
	string proposedLegalStatus;
	string proposedLegalDocs;
	uint256 bountyId;
	// string bondsToCreateProposal;
	// string timeBeforeProposalExpires;
	// string bondsToClaimBounty;
	// string timeToUnclaimBounty;
	Group newGroup;
	string targetGroupName;
	uint256 targetGroupId; //group Id  
	address memberToAdd;
	address memberToRemove;
	address contractAddrFnCall;
	string fnCallName;
	string fnCallAbi;
}

/**
 * @title Poll Status.
 * @notice
 */
enum PollStatus {
	ACTIVE,
	INACTIVE,
	APPROVED,
	FAILED,
	ENDED
}

/**
 * @title Poll Vote.
 * @notice Poll vote struct for the community poll voting
 */
struct PollVote {
	address voter;
	bool vote;  //true-like, false-dislike
	uint256 pollId;
}
