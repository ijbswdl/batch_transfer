//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract BatchTransfer is Ownable {
    uint256 public fee = 20000000;

    modifier collectFee() {
        require(msg.value >= fee, "Insufficient fee provided");
        _;
    }

    // 设置手续费方法
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // Batch transfer Ether
    function batchTransferEther(
        address payable[] calldata recipients,
        uint256[] calldata amounts
    ) external payable collectFee {
        uint256 length = recipients.length;
        require(
            length == amounts.length,
            "Recipients and amounts arrays must have the same length"
        );

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < length; i++) {
            totalTokens += amounts[i];
            recipients[i].transfer(amounts[i]);
        }
        require(totalTokens >= msg.value - fee, "msg.value - fee != amounts");

    }

    // Batch transfer ERC20 tokens
    function batchTransferToken(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable collectFee {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts arrays must have the same length"
        );

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalTokens += amounts[i];
        }

        token.transferFrom(msg.sender, address(this), totalTokens);

        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amounts[i]);
        }
    }

    function batchTransferTokenSimple(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable collectFee {
        require(
            recipients.length == amounts.length,
            "Recipients and amounts arrays must have the same length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    // 提取合约中存储的原生代币
    function withdrawNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No native tokens to withdraw");
        payable(msg.sender).transfer(balance);
    }

    // 提取合约中存储的ERC20代币
    function withdrawERC20Token(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No ERC20 tokens to withdraw");
        token.transfer(msg.sender, balance);
    }
}