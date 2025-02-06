// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

struct RewardData {
    address[] tokens;
    uint256[] totalAmounts;
    bytes32 root;
}

struct RewardVerificationData {
    uint256 rewardIndex;
    address[] tokens;
    uint256[] amounts;
    bytes32[] proof;
}
