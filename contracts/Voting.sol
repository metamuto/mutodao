//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CommunityPoll, PollVote, PollStatus, ProposeChanges} from "./Community/Poll.sol";
import {MemberOfCommRes, Group} from "./Community/Community.sol";

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
        counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
    counter._value = value - 1;
    }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

interface COMMUNITY{

	function proposalCreationRight(uint256 _type, uint256 commId, address senderAddr) external view returns (bool);
	function votingRight(uint256 _type, uint256 commId, address senderAddr) external view returns (bool);

	// proposed functions
	function transferBounty(uint256 amount, address account, uint256 commId) external returns (bool);
	// function createBounty(uint256 bountyAmount, uint256 availableClaims, uint256 daystoComplete, uint256 alreadyClaimed, uint256 commId) external returns (bool);
	function claimBounty(uint256 bountyAmount, address _targetAcc, uint256 commId) external returns (bool);
	function changeName(string memory name, uint256 commId) external returns (bool);
	function changePurpose(string memory purpose, uint256 commId) external returns (bool);
	function changelinks(string[] memory links, uint256 commId) external returns (bool);
	function changeLogoNCoverImage(string memory logoImage, string memory coverImage, uint256 commId) external returns (bool);
	function changeLegalStatusNDoc(string memory legalStatus, string memory legalDocuments, uint256 commId) external returns (bool);
	// function changeBondAndDeadline(string memory bond, string memory expiry, string memory bountyClaim, string memory timeToUnclaimFree, uint256 commId) external returns (bool);
	function createGroup(Group memory newGroup, uint256 commId) external returns (bool);
	function addMemberToGroup(address addr, uint256 groupId, uint256 commId) external returns (bool);
	function removeMemberToGroup(address addr, uint256 groupId, uint256 commId) external returns (bool);
}

/**
 * @title voting
 */
contract Voting {
	
	address communityContractAddress;
	COMMUNITY community; // community interface obj to call the community functions

	using Counters for Counters.Counter;
	Counters.Counter private _PollIds;
	Counters.Counter private _voteIds; 

	Counters.Counter private computeFlag;

	mapping(uint256 => CommunityPoll) private _pollData; //_PollIds -> poll
	mapping(uint256 => uint256[]) private _polls; //communityIds -> _PollIds
	 
	mapping(uint256 => PollVote) private _pollVotes; // _voteIds -> PollVote
	mapping(uint256 => uint256[]) private _votes; // _PollIds -> _voteIds

	event EvtCommunityPollCreate(uint256 pollId, uint256 startTimestamp, uint256 endTimestamp);
	event EvtCommunityPollDelete(uint256 pollId);
	event EvtCommunityPollVotes(uint256[] votesIds);
	event EvtCommunityPoll(CommunityPoll poll);

	/**contructor */
	constructor(address commAddr){
		communityContractAddress = commAddr;
		community = COMMUNITY(communityContractAddress); //to intialize the community contract
	}

	/**
	* @notice Cast vote for the community poll
	*/
	function communityVoteCast(uint256 commId, uint256 pollId, bool vote) external {
		CommunityPoll storage poll = pollFetch(pollId);
		//check wheather a member have a voting rights or not voted before
		require(isAlreadyVoted(pollId) != true, "You already voted.");
		require(poll.endTimeStamps > block.timestamp, "You cant vote because proposal time is ended.");
		require(community.votingRight(poll._type, commId, msg.sender) != false, "You dont have voting right.");
		PollVote memory pollvote = PollVote(
			msg.sender, //voter 
			vote,
			pollId
		);

		_voteIds.increment();
		uint256 voteId = _voteIds.current();
		_pollVotes[voteId] = pollvote;
		uint256[] storage votesIds = _votes[pollId];
		votesIds.push(voteId);
		_votes[pollId] = votesIds;
	}

	/**
	 * @notice Check Voter already voted or not
	 */
	function isAlreadyVoted(uint256 pollId) internal view returns(bool){

	// mapping(uint256 => PollVote) private _pollVotes; // _voteIds -> PollVote
	// mapping(uint256 => uint256[]) private _votes; // _PollIds -> _voteIds

		uint256[] memory voteIds = _votes[pollId];
		bool isVoted = false;
		for (uint256 index = 0; index < voteIds.length ; index++) {
			PollVote memory vote = _pollVotes[voteIds[index]];
			if(vote.voter == msg.sender){
				isVoted = true;
			}
		}
		return isVoted;
	}
	
	function VotesInfo(uint256 pollId) external {
		uint256[] memory voteIds = _votes[pollId];
		emit EvtCommunityPollVotes(voteIds);
	}

	/**
	* @notice get the details for the community poll
	*/
	function pollFetch(uint256 id) internal returns ( CommunityPoll storage ){

	// mapping(uint256 => CommunityPoll) private _pollData; //pollId -> poll
	// mapping(uint256 => uint256[]) private _polls; //communityIds -> pollIds
		require(id > 0, "No poll found with provided pollId");
		CommunityPoll storage poll = _pollData[id];
		return poll;
	}

	/**
	* @notice get the poll details
	*/
	function fetchPollData(uint256 id) external view returns(CommunityPoll memory){
		CommunityPoll storage poll = _pollData[id];
		return poll; 
	}
	
	/**
	* @notice create poll for the community (DAO)
	*/
	function communityPollCreate(uint256 daoId, uint256 pollType, ProposeChanges memory proposedChanges
	) external returns(bool){
		require(community.proposalCreationRight(pollType, daoId, msg.sender) != false, "You dont have permission to create proposal"); //check wheather a member have a proposal creation rights
		if(pollType == 8){
			CommunityPoll storage bountyPoll = pollFetch(proposedChanges.bountyId);
			require(bountyPoll.status == PollStatus.APPROVED, "Poll: Bounty failed, we can't move forward.");
		}
		
		_PollIds.increment();
		uint256 pollId = _PollIds.current();
		CommunityPoll memory poll = CommunityPoll(
			pollId,
			msg.sender, 
			PollStatus.ACTIVE,
			pollType,
			proposedChanges,
			block.timestamp,
			block.timestamp + 600,
			false
		);
		
		_pollData[pollId] = poll;
		uint256[] storage polls = _polls[daoId];
		polls.push(pollId);
		_polls[daoId] = polls;
		emit EvtCommunityPollCreate(pollId, block.timestamp, block.timestamp + 600);
		return true;
	}

	/**
	* @notice delete the community poll
	*/
	function communityPollDelete(uint256 pollId) external { 
		delete _polls[pollId];
		emit EvtCommunityPollDelete(pollId);
	}

	/**
	* @notice get votes details
	*/
	function getPollVotes(uint256 pollId) external view returns(uint256 agreed, uint256 reject){
		// PollVote[] memory pollVotes = _pollVotes[pollId];
		uint256[] memory voteIds = _votes[pollId];
		uint256 agreedVotesCount;
		uint256 rejectedVoteCount;
		for (uint256 index = 0; index < voteIds.length ; index++) {
			PollVote memory vote = _pollVotes[voteIds[index]];
			if(vote.vote){
				agreedVotesCount = agreedVotesCount + 1;
			}else {
				rejectedVoteCount = rejectedVoteCount + 1;
			}
		}
		return ( agreedVotesCount, rejectedVoteCount);
	}

	/**	
	* @notice compute poll result and return true or false
	*/
	function _computePollResult(uint256 communityId, uint256 pollId) internal returns(bool){
		
		CommunityPoll storage commPoll = pollFetch(pollId);
		
		require(commPoll.status != PollStatus.ENDED || commPoll.status != PollStatus.APPROVED || commPoll.status != PollStatus.FAILED, "Poll is already ended.");
		
		uint256[] memory voteIds = _votes[pollId];
	
		uint256 agreedVotesCount;
		uint256 rejectedVoteCount;
		for (uint256 index = 0; index < voteIds.length ; index++) {
			PollVote memory vote = _pollVotes[voteIds[index]];
			if(vote.vote){
				agreedVotesCount = agreedVotesCount + 1;
			}else {
				rejectedVoteCount = rejectedVoteCount + 1;
			}
		}
		if(agreedVotesCount > rejectedVoteCount) { 
			commPoll.result = true;
			return true;
		}else {
			commPoll.status = PollStatus.FAILED;
			return false;
		}
	}

	/**
	* @notice proposed changes
	*/
	function _doProposedChanges(uint256 commId, uint256 pollId) external returns (bool) { 
		computeFlag.increment(); // change the state to put this function in writeable function list
		if(_computePollResult(commId, pollId)){
			// get the proposed changes and call
			CommunityPoll storage commPoll = pollFetch(pollId);
			
			// 1- [amount, targetAcc],
			// 2- [bountyAmount, availableClaims, daystoComplete]
			// 3- [proposedDaoName]
			// 4- [proposedPurpose]
			// 5- [links]
			// 6- [proposedCover, proposedLogo] 
			// 7- [proposedLegalStatus, proposedLegalDocs] 
			// 8- [bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty] 
			// 9- [newGroupName, intialMemberAccount] 
			// 10- [targetGroupName, memberToAdd] 
			// 11- [targetGroupName, memberToRemove] 
			// 12-[] 
			// 13- [contractAddrFnCall, fnCallName, fnCallAbi]
			
			ProposeChanges memory proposechanges = commPoll.proposedChanges;
			bool res = false;
			
			if(commPoll._type == 1){
				res = community.transferBounty(proposechanges.amount, proposechanges.targetAcc, commId);

			}else if(commPoll._type == 2){
				// res = community.createBounty(proposechanges.bountyAmount, proposechanges.availableClaims, proposechanges.daystoComplete, proposechanges.alreadyClaimed, commId);

			}else if(commPoll._type == 3){
				res = community.changeName(proposechanges.proposedDaoName, commId);

			}else if(commPoll._type == 4){
				res = community.changePurpose(proposechanges.proposedPurpose, commId);

			}else if(commPoll._type == 5){
				res = community.changelinks(proposechanges.links, commId);

			}else if(commPoll._type == 6){
				res = community.changeLogoNCoverImage(proposechanges.proposedLogo, proposechanges.proposedCover, commId);

			}else if(commPoll._type == 7){
				res = community.changeLegalStatusNDoc(proposechanges.proposedLegalStatus, proposechanges.proposedLegalDocs, commId);
			
			}else if(commPoll._type == 8){
				CommunityPoll storage bountyPoll = pollFetch(proposechanges.bountyId);
				ProposeChanges memory bountyProposedChanges = bountyPoll.proposedChanges;
				require(commPoll.status != PollStatus.APPROVED, "Poll: Bounty failed, we can't move forward.");
				if(bountyProposedChanges.alreadyClaimed < bountyProposedChanges.availableClaims){
					res = community.claimBounty(bountyProposedChanges.bountyAmount, bountyPoll.creator, commId );
					bountyProposedChanges.alreadyClaimed  = bountyProposedChanges.alreadyClaimed + 1;
				}
			}else if(commPoll._type == 9){
				res = community.createGroup(proposechanges.newGroup, commId);
	
			}else if(commPoll._type == 10){
				res = community.addMemberToGroup(proposechanges.memberToAdd, proposechanges.targetGroupId, commId);

			}else if(commPoll._type == 11){
				res = community.removeMemberToGroup(proposechanges.memberToRemove, proposechanges.targetGroupId, commId);

			}else if(commPoll._type == 12){
				// noting to do for this type of proposal

			}else if(commPoll._type == 13){
			}else {}
			commPoll.status = PollStatus.APPROVED;
			return res;
		}
	}
}

