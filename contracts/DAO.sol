//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IERC20.sol";

contract DAO {
  IERC20 public token;
  address public owner;
  address public cahairPerson;
  uint256 public minQuorum;
  uint256 public debathingPeriod;
  uint256 public proposalCount;
  uint256 public balance;

  event PositiveDecisionProposal(uint256 id, bool success);

  struct Proposal {
    uint256 timestamp; //время создания
    uint256 voteFor; // вес за
    uint256 voteAgainst; //вес против
    bytes callData;
    address recipient;
    bool isFinished;
    string description;
    // каким количеством проголосовал
    mapping(address => uint256) votingRegistr;
  }

  mapping(uint256 => Proposal) public proposals;

  mapping(address => uint256) public userBalance;

  modifier onlyTokenholders() {
    require(userBalance[msg.sender] > 0, "Only tokenholders");
    _;
  }

  modifier onlyChairPerson() {
    require(msg.sender == cahairPerson, "Only chairPerson can make it");
    _;
  }

  constructor(
    address _tokenAddress,
    address _chairPerson,
    uint256 _minQuorum,
    uint256 _debathingPeriod
  ) {
    owner = msg.sender;
    token = IERC20(_tokenAddress);
    cahairPerson = _chairPerson;
    minQuorum = _minQuorum;
    debathingPeriod = _debathingPeriod;
    proposalCount = 0;
  }

  function getUserBalance(address _address) public view returns (uint256) {
    return userBalance[_address];
  }

  function getProposal(uint256 _id)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      address,
      string memory
    )
  {
    return (
      proposals[_id].timestamp,
      proposals[_id].voteFor,
      proposals[_id].voteAgainst,
      proposals[_id].recipient,
      proposals[_id].description
    );
  }

  function getProposalsCount() external view returns (uint256) {
    return proposalCount;
  }

  function topUpBalance(uint256 _amount) external returns (uint256) {
    token.transferFrom(msg.sender, address(this), _amount);
    userBalance[msg.sender] += _amount;
    balance += _amount;
    return userBalance[msg.sender];
  }

  function reduceBalance(uint256 _amount) external {
    require(
      _amount <= getUserBalance(msg.sender),
      "The amount more then balance"
    );
    require(!isUserVoting(msg.sender), "Wait for the end of voting");

    // не протестировано
    token.transferFrom(address(this), msg.sender, _amount);
    userBalance[msg.sender] -= _amount;
    balance -= _amount;
  }

  function isUserVoting(address _address) internal view returns (bool) {
    uint256 count = 0;

    for (uint256 i = 1; i <= proposalCount; i++) {
      if (
        !proposals[i].isFinished && proposals[i].votingRegistr[_address] > 0
      ) {
        count++;
      }
    }
    return count > 0;
  }

  function addProposal(
    bytes memory _callData,
    address _recipient,
    string memory _desc
  ) external onlyChairPerson {
    proposalCount++;

    Proposal storage proposal = proposals[proposalCount];

    proposal.timestamp = block.timestamp;
    proposal.description = _desc;
    proposal.recipient = _recipient;
    proposal.callData = _callData;
  }

  function vote(uint256 _proposalId, bool supportAgainst)
    external
    onlyTokenholders
  {
    // несуществующее предложение
    require(proposals[_proposalId].timestamp != 0, "No proposal");
    // ещё не голосовал
    require(
      proposals[_proposalId].votingRegistr[msg.sender] ==
        getUserBalance(msg.sender),
      "Vote is already taken into account"
    );
    // голосование не закончилось
    // require(
    //   (block.timestamp - proposals[_proposalId].timestamp) > debathingPeriod,
    //   "Vote is finished"
    // );

    supportAgainst
      ? proposals[_proposalId].voteAgainst += userBalance[msg.sender]
      : proposals[_proposalId].voteFor += userBalance[msg.sender];

    proposals[_proposalId].votingRegistr[msg.sender] = userBalance[msg.sender];
  }

  function finishProposal(uint256 _proposalId) external {
    // голосование еще не было финишировано
    require(proposals[_proposalId].isFinished == false, "Vote is finished");

    // голосование закончилось
    require(
      (block.timestamp - proposals[_proposalId].timestamp) <= debathingPeriod,
      "Voting time isn't up"
    );

    proposals[_proposalId].isFinished = true;

    bool quorum = (proposals[_proposalId].voteFor +
      proposals[_proposalId].voteAgainst) > minQuorum;

    if (
      quorum &&
      (proposals[_proposalId].voteFor > proposals[_proposalId].voteAgainst)
    ) {
      (bool success, ) = proposals[_proposalId].recipient.call(
        proposals[_proposalId].callData
      );
      emit PositiveDecisionProposal(_proposalId, success);
    }
  }
}
