// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./Staker.sol";

contract ExampleExternalContract {
    bool public completed;
    address public stakerAddress;

    function complete() public payable {
        completed = true;

        //to save the address of the EOA calling Staker contract execute(), hence using msg.sender
        stakerAddress = address(msg.sender);
    }

    function sendMoneyBack(address _to) public {
        //to check if there's any balance in this contract, otherwise no point calling
        require(address(this).balance > 0, "No balance to send");

        //this is to ensure we don't just allow anyone to call this function
        require(_to == stakerAddress, "Nice try ;) ");

        //sending the entire contract balance back to Staker
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Failed to send back");

        completed = false;
    }
}
