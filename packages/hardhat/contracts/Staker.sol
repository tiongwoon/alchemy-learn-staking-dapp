// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; 

import "./ExampleExternalContract.sol";

contract Staker {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTimestamps;


    //using this to 'reset' staking when we get back balance from External
    uint256 public timerInit = block.timestamp;
    uint256 public withdrawalDeadline = timerInit + 150 seconds;
    uint256 public claimDeadline = timerInit + 300 seconds;
    uint256 public currentBlock = 0;
    uint256 public withdrawTimestamp; 


    ExampleExternalContract public exampleExternalContract;
    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint256);
    event Execute(address indexed sender, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function withdrawalTimeLeft()
        public
        view
        returns (uint256 withdrawalTimeLeft)
    {
        if (block.timestamp >= withdrawalDeadline) {
            return (0);
        } else {
            return (withdrawalDeadline - block.timestamp);
        }
    }

    function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
        if (block.timestamp >= claimDeadline) {
            return (0);
        } else {
            return (claimDeadline - block.timestamp);
        }
    }

    modifier withdrawalDeadlineReached(bool requireReached) {
        uint256 timeRemaining = withdrawalTimeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Withdrawal period is not reached yet");
        } else {
            require(timeRemaining > 0, "Withdrawal period has been reached");
        }
        _;
    }

    modifier claimDeadlineReached(bool requireReached) {
        uint256 timeRemaining = claimPeriodLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Claim deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Claim deadline has been reached");
        }
        _;
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Stake already completed");
        _;
    }

    function stake()
        public
        payable
        withdrawalDeadlineReached(false)
        claimDeadlineReached(false)
    {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
        emit Stake(msg.sender, msg.value);
    }

    function withdraw()
        public
        withdrawalDeadlineReached(true)
        claimDeadlineReached(false)
        notCompleted
    {
        require(balances[msg.sender] > 0);
        uint256 individualBalance = balances[msg.sender];
        balances[msg.sender] = 0;

        withdrawTimestamp = block.timestamp;
        uint256 indBalanceRewards = individualBalance +
        (((block.timestamp - depositTimestamps[msg.sender])**2) * 1000000000000000);
        (bool sent, ) = msg.sender.call{
            value: indBalanceRewards
        }("");
        require(sent, "RIP: Withdrawal failed");
    }

    function execute() public notCompleted claimDeadlineReached(true) {
        uint256 contractBalance = address(this).balance;
        exampleExternalContract.complete{value: address(this).balance}();
        emit Execute(msg.sender, contractBalance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBack() external {
        exampleExternalContract.sendMoneyBack(address(this));
        timerInit = block.timestamp;
        claimDeadline = timerInit + 300 seconds;
        withdrawalDeadline = timerInit + 150 seconds;
    }
}
