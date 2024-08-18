// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console, Vm} from "forge-std/Test.sol";
import {MockCCIPRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/test/mocks/MockRouter.sol";
import "../script/Helper.sol";
import "../src/bootcamp-day3/TransferUSDC.sol";
import "../src/bootcamp-day3/UsdcReceiver.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";

contract MockUsdc is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockUsdc", "MockUsdc") {
        _mint(msg.sender, initialSupply);
    }
}

contract TransferUSDTTest is Test, Helper {
    // Declaration of contracts and variables used in the tests.
    TransferUSDC public sender;
    UsdcReceiver public receiver;
    BurnMintERC677 public link;
    MockCCIPRouter public router;

    MockUsdc public usdcToken;

    address eoaaa = address(0x123);

    // A specific chain selector for identifying the chain.

    function setUp() public {
        router = new MockCCIPRouter();
        link = new BurnMintERC677("ChainLink Token", "LINK", 18, 10 ** 27);
        usdcToken = new MockUsdc(10000 * 1e18);
        usdcToken.transfer(eoaaa, 100 * 1e18);
        vm.startPrank(eoaaa);

        sender = new TransferUSDC(
            address(router),
            address(link),
            address(usdcToken)
        );
        usdcToken.approve(address(sender), 1e18);

        // Mock router and LINK token contracts are deployed to simulate the network environment.
        // usdcToken.transfer(eoaaa, 100 * 1e18);

        // (, address linkToken, , ) = getConfigFromNetwork(
        //     SupportedNetworks.AVALANCHE_FUJI
        // );

        // sender.allowlistDestinationChain(chainIdEthereumSepolia, true);
        // console.log("sender: ", address(sender));

        receiver = new UsdcReceiver(address(router));
        console.log("receiver: ", address(receiver));
        sender.allowlistDestinationChain(chainIdEthereumSepolia, true);
        vm.stopPrank();

        // IERC20(usdcAvalancheFuji).approve(address(sender), 1e5);
    }

    function test_SendReceive() public {
        vm.startPrank(eoaaa);
        vm.recordLogs(); // Starts recording logs to capture events.
        sender.transferUsdc(
            chainIdEthereumSepolia,
            address(receiver),
            1e5,
            600000
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 msgExecutedSignature = keccak256(
            "MsgExecuted(bool,bytes,uint256)"
        );

        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == msgExecutedSignature) {
                (, , uint256 gasUsed) = abi.decode(
                    logs[i].data,
                    (bool, bytes, uint256)
                );
                console.log("!!! Gas used: %d", gasUsed);
            }
        }
    }
}
