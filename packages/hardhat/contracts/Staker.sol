// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

contract Staker {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTimestamps;
    uint256 public constant rewardRatePerSecond = 0.1 ether;

    //using this to 'reset' staking when we get back balance from External
    uint256 public timerInit = block.timestamp;
    uint256 public withdrawalDeadline = timerInit + 100 seconds;
    uint256 public claimDeadline = timerInit + 150 seconds;
    uint256 public currentBlock = 0;
    //1.02092
    //uint256 public constant rewardExponentialConstant = 1025;
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
        uint256 indBalanceRewards = individualBalance +
            ((block.timestamp - depositTimestamps[msg.sender]) *
                rewardRatePerSecond);
        balances[msg.sender] = 0;
        //uint256 indBalanceRewards = individualBalance + (((rewardExponentialConstant/1000) ** block.timestamp - depositTimestamps[msg.sender])*1000000000000000000);
        //exponential function we will be using is y = 1.025^x 

        // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
        (bool sent, bytes memory data) = msg.sender.call{
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
        claimDeadline = timerInit + 150 seconds;
        withdrawalDeadline = timerInit + 100 seconds;
    }
}

// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
// ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

// After some `deadline` allow anyone to call an `execute()` function
// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

// Add the `receive()` special function that receives eth and calls stake()
