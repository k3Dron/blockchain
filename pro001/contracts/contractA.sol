// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract contractA {
    address public here;
    string public message;
    address public friend;

    constructor() {
        here = msg.sender;
    }

    function friendAddress(address hey) public {
        friend = hey;
    }

    function updateMessage(string memory naya) public {
        message = naya;
    }

    function send(string memory naya) public {
        contractA other = contractA(friend);
        other.updateMessage(naya);
    }
}
