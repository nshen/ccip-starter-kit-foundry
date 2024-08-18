// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

import "../src/bootcamp-day3/TransferUSDC.sol";
import "../src/bootcamp-day3/UsdcReceiver.sol";

contract TransferUSDCScript is Script, Helper {
    IERC20 public linkERC20;
    uint256 senderPrivateKey;

    function run() external {
        senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        //-------------------------------
        // source chain
        //----------------------------------
        (
            address ccipRouter,
            address linkToken,
            address wrappedNative,
            uint64 chainId
        ) = getConfigFromNetwork(SupportedNetworks.AVALANCHE_FUJI);

        console.log("ccipRouter:", ccipRouter);
        console.log("linkToken:", linkToken);
        console.log("wrappedNative:", wrappedNative);
        console.log("chainId:", chainId);

        // 步骤1）将TransferUSDC.sol部署到Avalanche Fuji
        TransferUSDC tu = new TransferUSDC(
            ccipRouter,
            linkToken,
            usdcAvalancheFuji
        );

        // TransferUSDC tu = TransferUSDC(
        //     0x295c5e98Da276dc6c3F2812ca76D42fefF783b56
        // );

        // Derive the sender's address from the private key
        address sender = vm.addr(senderPrivateKey);

        // 步骤2）在Avalanche Fuji上调用allowlistDestinationChain函数
        tu.allowlistDestinationChain(chainIdEthereumSepolia, true);

        // 步骤3）在Avalanche Fuji上，向TransferUSDC.sol合约充值3个LINK。
        linkERC20 = IERC20(linkToken);
        uint256 linkbalance = linkERC20.balanceOf(sender);
        require(linkbalance >= 3e18, "Insufficient LINK balance");
        console.log(linkbalance);
        bool success = linkERC20.transfer(address(tu), 0.002e18);
        require(success, "LINK transfer failed");

        // 步骤4）在Avalanche Fuji上，调用USDC.sol合约的approve函数。
        // 批准TransferUSDC.sol代表我们支出1个USDC
        IERC20(usdcAvalancheFuji).approve(address(tu), 1e6);

        // 部署 receiver 到 ethereum sepolia
        (address sepoliaCCIPRouter, , , ) = getConfigFromNetwork(
            SupportedNetworks.ETHEREUM_SEPOLIA
        );
        UsdcReceiver receiver = new UsdcReceiver(sepoliaCCIPRouter);
        console.log("receiver: ", address(receiver));
        //0x1E4Fb722EE4BAC137a267c5a1bcb7e37AEe8a629

        // UsdcReceiver receiver = UsdcReceiver(
        //     0x1E4Fb722EE4BAC137a267c5a1bcb7e37AEe8a629
        // );
        // (bytes32 messageId, , , ) = receiver.getLatestMessageDetails();
        // console.logBytes32(messageId);

        // 提前运行 TransferUSDT.t.sol 得到Gas 预估值
        // !!! Gas used: 107088

        // 步骤5）在Avalanche Fuji上调用transferUsdc函数，写入预估值增加10%。
        uint64 gaslimit = (uint64(107088) * 11) / 10;

        tu.transferUsdc(
            chainIdEthereumSepolia,
            address(0x1E4Fb722EE4BAC137a267c5a1bcb7e37AEe8a629),
            1e5,
            gaslimit
        );

        vm.stopBroadcast();
    }
}
