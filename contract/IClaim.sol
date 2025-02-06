// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { RewardVerificationData } from "./Types.sol";

/// @title IClaim
/// interface for Claim contract containing all events, errors and external/public functions
interface IClaim {
    /////////////////////////////////
    ////////////  EVENTS  ///////////
    /////////////////////////////////

    /// @notice emitted when a new reward period is added
    /// @param rewardIndex index of the reward period
    /// @param tokens array of token addresses for the rewards
    /// @param totalAmounts array of total amounts for each token
    /// @param merkleRoot merkle root for verifying claims
    event RewardAdded(
        uint256 rewardIndex,
        address[] tokens,
        uint256[] totalAmounts,
        bytes32 merkleRoot
    );

    /// @notice emitted when a user claims rewards
    /// @param user address of the user claiming the rewards
    /// @param claims array of reward verification data
    event RewardsClaimed(
        address user, RewardVerificationData[] claims
    );

    /// @notice emitted when tokens are withdrawn by the admin
    /// @param token address of the token withdrawn
    /// @param amount amount of the token withdrawn
    event TokensWithdrawn(address token, uint256 amount);

    /////////////////////////////////
    ////////////  ERRORS  ///////////
    /////////////////////////////////

    /// @notice thrown when a user tries to claim a reward that has already been claimed
    error Claim_RewardAlreadyClaimed();

    /// @notice thrown when the provided merkle proof is invalid
    error Claim_InvalidMerkleProof();

    /// @notice thrown when attempting to initialize with zero address
    error Init_ZeroAddress();

    /// @notice thrown when attempting to provide rewards with a zero address token
    error ProvideRewards_ZeroAddress();

    /// @notice thrown when attempting to provide rewards with a zero amount
    error ProvideRewards_ZeroAmount();

    /// @notice thrown when attempting to provide rewards with an invalid merkle root
    error ProvideRewards_InvalidMerkleRoot();

    /// @notice thrown when attempting to provide rewards with an input length mismatch
    error ProvideRewards_InputLengthMismatch();

    /////////////////////////////////
    ////////////  FUNCTIONS  ////////
    /////////////////////////////////

    /// @notice initializes the contract
    /// @param admin address of the admin
    function __Claim_init(address admin) external;

    /// @notice provides rewards for a new reward period
    /// @param tokens array of token addresses for the rewards
    /// @param totalAmounts array of total amounts for each token
    /// @param merkleRoot merkle root for verifying claims
    function provideRewards(
        address[] calldata tokens,
        uint256[] calldata totalAmounts,
        bytes32 merkleRoot
    ) external;

    /// @notice allows a user to claim a reward
    /// @param claims array of reward verification data
    function claimRewards(RewardVerificationData[] calldata claims) external;

    /// @notice allows the admin to withdraw tokens
    /// @param token address of the token to withdraw
    /// @param amount amount of the token to withdraw
    function withdrawTokens(address token, uint256 amount) external;

    /// @notice pauses the contract
    function pause() external;

    /// @notice unpauses the contract
    function unpause() external;

    /// @notice returns whether a user has claimed a reward for a given reward period
    /// @param user address of the user
    /// @param rewardIndex index of the reward period
    /// @return claimed whether the user has claimed the reward
    function isClaimed(address user, uint256 rewardIndex)
        external
        view
        returns (bool claimed);

    /// @notice returns the reward data for a given reward index
    /// @param rewardIndex index of the reward period
    /// @return tokens array of token addresses for the reward period
    /// @return amounts array of total amounts for each token
    /// @return merkleRoot merkle root for verifying claims
    function getRewardPeriodData(uint256 rewardIndex)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            bytes32 merkleRoot
        );
}
