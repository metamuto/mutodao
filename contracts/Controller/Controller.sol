//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {Voting} from "../Voting.sol";
import {Community, CommunityStatus, Group, MemberOfCommRes } from "../Community/Community.sol";
import {CommunityPoll, ProposeChanges} from "../Community/Poll.sol";
import {Initializable, OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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

/**
* @title polling and Voting interface 
*/
interface VotingPoll {
    function _computePollResult(uint256 communityId, uint256 pollId) external view returns(uint256 agreeVotes, uint256 rejectedVotes);
    // will add other function according to requirement
} 
/**
* @title erc20 token interface
*/
interface ERC20 {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}  

/** proposed changes 
1- [amount, targetAcc],
2- [bountyAmount, availableClaims, daystoComplete]
3- [proposedDaoName]
4- [proposedPurpose]
5- [links]
6- [proposedCover, proposedLogo] 
7- [proposedLegalStatus, proposedLegalDocs] 
8- [bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty] 
9- [newGroupName, intialMemberAccount] 
10- [targetGroupName, memberToAdd] 
11- [targetGroupName, memberToRemove] 
12-[] 
13- [contractAddrFnCall, fnCallName, fnCallAbi] */

/**
 * @title DAO Controller
 * @author Michael Brich
 * @notice Primary controller handling DAO calls.
 */
contract ControllerMUTO is Initializable, UUPSUpgradeable, OwnableUpgradeable {

	using Counters for Counters.Counter;

    Counters.Counter private _CommunityIds;
    Counters.Counter private _Group;
    Counters.Counter private _MemberIds;

    address votingContractAddress;
    address tokenAddress;

    // Events to emit
	event EvtCommunityCreate( uint256 id, uint256[] groupIds);
	event EvtCommunitySuspend( string reason );
	event EvtCommunityUnsuspend( string reason );
	event EvtCreateGroup( uint256 groupId );

	mapping(uint256 => Community) private _communities; // _CommunityIds -> Community
    mapping(uint256 => Group[]) private _communityGroups; // _CommunityIds -> Group 
    
	/**
	 * @notice Address of the Proxy contract which delegates calls to this contract.
	 */
	address private _controllerProxy;
	/**
	 * @notice Flag indicating whether this contract is actively used by the Proxy Contract.
	 * Set to false after the Proxy Contract successfully completes an upgrade call and targets
	 * a new proxied contract.
	 */
	bool private _active;

	/**
	 * @notice Called once by the DAO Proxy contract to initialize contract values
	 * and properties. Only callable once during init.
	 */
	function initialize(address tokenAddr) public initializer {
		setControllerProxy(msg.sender);
        __Ownable_init();
        __UUPSUpgradeable_init();
        tokenAddress = tokenAddr;
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}

	function activate() external onlyInitializing {
		_active = true;
	}

	function deactivate() external {
		_active = false;
	}

    /**
    * @notice set the voting contract address
    */
    function setVotingContractAddress(address votingContractAddr) external onlyOwner {
        votingContractAddress = votingContractAddr;
    }

    /**
    * @notice assert voting contract address 
    */
    function assertVotingContractAddr() internal returns(bool){
        if(msg.sender == votingContractAddress){
            return true;
        }else {
            return false;
        }
    }

	function fetchAssertCommunity(uint256 id, string memory errorMsg) internal view returns (Community storage) {
		Community storage comm = fetchCommunity(id);
		require(comm.id > 0, string(abi.encodePacked("Community Not Found - ", errorMsg)));

		return comm;
	}

	/**
	 * @notice Retrieve data for target community if it exists. Used internally by various calls to validate
	 * community status, permissions, etc.
	 */
	function fetchCommunity(uint256 id) internal view returns (Community storage) {
		Community storage comm = _communities[id];
		if (comm.createBlock < 1) {
			return comm;
		}

		return comm;
	}

	/**
	 * @notice Set the proxy contract address which will call this contract. Can only be
	 * set once during contract initialization.
	 * @param target	-	Address of proxy contract using this contract. Should only be set
	 *						once during contract init.
	 */
	function setControllerProxy(address target) internal initializer returns (bool) {
		_controllerProxy = target;

		return true;
	}

    /**
     * @notice check groups details of the particular dao
     */
    function communityGroupsDetail(uint256 daoId) public view returns(Group[] memory group) {
        Group[] storage groups = _communityGroups[daoId];
        return groups;
    }   

    /**
     * @notice check details of the dao
     */
    function communityDetail(uint256 daoId) public view returns(Community memory) {
		Community storage comm = _communities[daoId];
        return comm;
    }   


    /**
     * @notice create group of community and return array of id of the group
     */
    function createCommunityGroup(uint256 daoId, Group[] memory group) internal returns(uint256[] memory id) { 
        uint256[] memory groupIdsArr = new uint256[](group.length);
        for (uint256 index = 0; index < group.length; index++) {
            _Group.increment();
            uint256 groupId =  _Group.current();
            Group memory groupObj = Group(
                groupId,
                group[index].name,
                group[index].members, //this should be an array 
                group[index].proposalCreation, //permission
                group[index].voting //permission
            );
            Group[] storage groupArr = _communityGroups[daoId];
            groupArr.push(groupObj);
            groupIdsArr[index]= groupId;
        }           
        return groupIdsArr;
    }

	/**
	 * @notice Create a Freedom MetaDAO Community using the provided parameters. Caller becomes
	 * the first member and admin automatically if the action succeeds.
	 */
	 
	function communityCreate(string memory name, string memory purpose, string memory legalStatus, string memory legalDocuments, string[] memory links, Group[] memory group, string memory logoImage, string memory coverImage) external onlyProxy returns (bool) {
		_CommunityIds.increment();
        uint256 commId = _CommunityIds.current(); 
        uint256[] memory groupIdsArr;
        
        // if array of group is empty or not
        if(group.length >= 0){
            groupIdsArr = createCommunityGroup(commId, group);
        }

        // group ids for the community

		Community memory communityDetails = Community(
			commId,
			CommunityStatus.ACTIVE,
			// groupIdsArr,
			block.number,
			block.timestamp,
			msg.sender,
            name, // name 
            purpose, // purpose
            links, // links array
            coverImage, // coverImage
            logoImage, // logoImage
            legalStatus, // legalStatus
            legalDocuments, //legalDocuments
            "", // bonds to create proposal
            "", // timeBeforeProposalExpires
            "", // bondsToClaimBounty
            "",  // timeToUnclaimBounty
            0
		);
		_communities[commId] =  communityDetails;

		emit EvtCommunityCreate(commId, groupIdsArr);
        return true;
	}

    /**
     * @notice transfer a bounty
     */
    function transferBounty(uint256 _amount, address _targetAcc, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        require(comm.balance >= _amount, "Insufficient balance");
        ERC20(tokenAddress).transfer(_targetAcc, _amount);
        comm.balance = comm.balance - _amount;
        return true;
    }

    /**
     * @notice deposit amount to community 
     */
    function depositAmount(uint _amount, uint256 commId) external onlyProxy returns (bool) {
        // require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        // deposit amount
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
        comm.balance = comm.balance + _amount;
        return true;
    }

    /**
     * @notice create a bounty
     */
    // function createBounty(string memory bountyAmount, uint256 availableClaims, uint256 daystoComplete, uint256 alreadyClaimed, uint256 commId) external onlyProxy returns (bool){
    //     require(assertVotingContractAddr() == true, "Unauthorized user.");
    //     Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
    //     // create bounty address 
    //     return true;
    // }

    /**
     * @notice change the community name with proposed change
     */
    function changeName(string memory proposedDaoName, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        comm.name = proposedDaoName;
        return true;
    }

    /**
     * @notice change the community purpose description with proposed change
     */
    function changePurpose(string memory proposedPurpose, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        comm.purpose = proposedPurpose;
        return true;
    }

    /**
     * @notice change the community links with proposed change
     */
    function changelinks(string[] memory links, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        comm.links = links;
        return true;
    }

    /**
     * @notice change the community logo image with proposed change
     */
    function changeLogoNCoverImage(string memory logoImage, string memory coverImage, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        comm.logo = logoImage;
        comm.cover = coverImage;
        return true;
    }

    /**
     * @notice change the community legal status with proposed change
     */
    function changeLegalStatusNDoc(string memory legalStatus, string memory legalDocuments, uint256 commId) external onlyProxy returns (bool){
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        comm.legalStatus = legalStatus;
        comm.legalDocs = legalDocuments;
        return true;
    }
    
    /**
     * @notice add member to group - internal function
     */
    function addMemberToGroup(address addr, uint256 groupId, uint256 commId) external onlyProxy returns (bool){  
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Group[] storage group = _communityGroups[commId];
        for (uint256 index = 0; index < group.length; index++) {
            if(group[index].id == groupId){
                address[] storage members = group[index].members;
                 members.push(addr);   
            }
        }
        return true;
    }

    /**
     * @notice remove member from group - internal function
     */
    function removeMemberToGroup(address addr, uint256 groupId, uint256 commId) external onlyProxy returns (bool){  
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        bool isRemoved = false;
        Group[] storage group = _communityGroups[commId];

        for (uint256 index = 0; index < group.length; index++) {
            if(group[index].id == groupId){
                address[] storage members = group[index].members;
                for (uint256 j = 0; j < members.length; j++) {
                    if(members[j] == addr){
                        members[j] = address(0);
                        isRemoved = true; 
                    }
                }
            }
        }
        return isRemoved; 
    }

    /**
    * @notice claim bounty
     */
    //  bountyProposedChanges.bountyAmount, msg.sender, commId
    function claimBounty(uint256 bountyAmount, address _targetAcc, uint256 commId) external onlyProxy returns (bool) {
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        Community storage comm = fetchAssertCommunity(commId, "Comm: Doesn't exist");
        // require(comm.balance >= bountyAmount, "Insufficient balance");
        ERC20(tokenAddress).transfer(_targetAcc, bountyAmount);
        comm.balance = comm.balance - bountyAmount;
        return true;
    }

    /* @notice create group
    */
    function createGroup(Group memory newGroup, uint256 commId) external onlyProxy returns (bool) {
        require(assertVotingContractAddr() == true, "Unauthorized user.");
        fetchAssertCommunity(commId, "Comm: Doesn't exist");
        // create group in particular community
        _Group.increment();
        uint256 groupId =  _Group.current();
        Group memory groupObj = Group(
            groupId,
            newGroup.name,
            newGroup.members, //this should be an array 
            newGroup.proposalCreation, //permission
            newGroup.voting //permission
        );
        Group[] storage groups = _communityGroups[commId];
        groups.push(groupObj);
        emit EvtCreateGroup(groupId);
        return true;
    }
    
	/**
	* @notice Is member of that community
	*/
	function isMemberOfCommunity(uint256 commId, address senderAddr) internal view returns (MemberOfCommRes memory){
        MemberOfCommRes memory res;
        res.isMember = false;
        res.groupId = 0; 
        Group[] memory groups = _communityGroups[commId];
        for (uint256 i = 0; i < groups.length; i++) {
            address[] memory memberAddr = groups[i].members;
            for (uint256 j = 0; j < memberAddr.length; j++) {
                if( memberAddr[j] == senderAddr ){
                    res.isMember = true;
                    res.groupId = groups[i].id;
                    res.proposalCreation = groups[i].proposalCreation;
                    res.voting = groups[i].voting;
                    return res;
                }
            }
        }
        return res;
	}

    /**
    * @notice Do member have proposal creation rights
    */
    function proposalCreationRight(uint256 _type, uint256 commId, address senderAddr) external view returns (bool) {        
        bool haveRights = false;
        Group[] memory groups = _communityGroups[commId];
        for (uint256 i = 0; i < groups.length; i++) {
            address[] memory memberAddr = groups[i].members;
            for (uint256 j = 0; j < memberAddr.length; j++) {
                if( memberAddr[j] == senderAddr ){
                    for (uint256 k = 0; k < groups[i].proposalCreation.length; k++) {
                        if(_type == groups[i].proposalCreation[k]){
                            haveRights = true;
                            return haveRights;
                        }
                    }
                }
            }
        }
        return haveRights;
    }

    /**
    * @notice Do member have voting rights on proposal
    */
    function votingRight(uint256 _type, uint256 commId, address senderAddr) external view returns (bool) {        
        bool haveRights = false;
        Group[] memory groups = _communityGroups[commId];
        for (uint256 i = 0; i < groups.length; i++) {
            address[] memory memberAddr = groups[i].members;
            for (uint256 j = 0; j < memberAddr.length; j++) {
                if( memberAddr[j] == senderAddr ){
                    for (uint256 k = 0; k < groups[i].voting.length; k++) {
                        if(_type == groups[i].voting[k]){
                            haveRights = true;
                            return haveRights;
                        }
                    }
                }
            }
        }
        return haveRights;
    }
}
