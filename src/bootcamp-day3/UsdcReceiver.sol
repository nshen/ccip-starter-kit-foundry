// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract UsdcReceiver is CCIPReceiver {
    bytes32 latestMessageId;
    uint64 latestSourceChainSelector;
    address latestSender;
    uint256 latestAmount;

    event MessageReceived(
        bytes32 latestMessageId,
        uint64 latestSourceChainSelector,
        address latestSender,
        address lastReceivedTokenAddress,
        uint256 lastReceivedTokenAmount,
        uint256 result
    );

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        latestMessageId = message.messageId;
        latestSourceChainSelector = message.sourceChainSelector;
        latestSender = abi.decode(message.sender, (address));
        address lastReceivedTokenAddress;
        uint256 lastReceivedTokenAmount;

        lastReceivedTokenAddress = address(0); // message.destTokenAmounts[0].token;
        lastReceivedTokenAmount = 0; // message.destTokenAmounts[0].amount;

        // 增加复杂度，耗费更多的gas
        uint256 result = 0;
        for (uint256 i = 0; i < 300; i++) {
            result += i;
        }

        emit MessageReceived(
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            lastReceivedTokenAddress,
            lastReceivedTokenAmount,
            result
        );
    }

    function getLatestMessageDetails()
        public
        view
        returns (bytes32, uint64, address, uint256)
    {
        return (
            latestMessageId,
            latestSourceChainSelector,
            latestSender,
            latestAmount
        );
    }
}
