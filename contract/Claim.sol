// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC20 } from "@oz/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from
    "@oz/contracts/utils/cryptography/MerkleProof.sol";
import { SafeERC20 } from
    "@oz/contracts/token/ERC20/utils/SafeERC20.sol";

import { AccessControlUpgradeable } from
    "@oz-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from
    "@oz-upgradeable/utils/PausableUpgradeable.sol";
import { UUPSUpgradeable } from
    "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { EnumerableSet } from
    "@oz/contracts/utils/structs/EnumerableSet.sol";

import { ClaimStorage as Storage } from "./ClaimStorage.sol";
import { IClaim } from "./IClaim.sol";
import { RewardData, RewardVerificationData } from "./Types.sol";

contract Claim is
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    IClaim
{
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(MANAGER_ROLE)
    { }

    /// @inheritdoc IClaim
    function __Claim_init(address admin) external initializer {
        if (admin == address(0)) {
            revert Init_ZeroAddress();
        }

        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IClaim
    function provideRewards(
        address[] calldata tokens,
        uint256[] calldata totalAmounts,
        bytes32 merkleRoot
    ) external onlyRole(MANAGER_ROLE) {
        uint256 length = tokens.length;
        if (length == 0 || length != totalAmounts.length) {
            revert ProvideRewards_InputLengthMismatch();
        }

        if (merkleRoot == bytes32(0)) {
            revert ProvideRewards_InvalidMerkleRoot();
        }

        Storage.Layout storage $ = Storage.layout();

        for (uint256 i = 0; i < length;) {
            address token = tokens[i];
            uint256 amount = totalAmounts[i];

            if (token == address(0)) {
                revert ProvideRewards_ZeroAddress();
            }
            if (amount == 0) revert ProvideRewards_ZeroAmount();

            IERC20(token).safeTransferFrom(
                msg.sender, address(this), amount
            );

            ++i;
        }

        $.rewardPeriods.push(
            RewardData({
                tokens: tokens,
                totalAmounts: totalAmounts,
                root: merkleRoot
            })
        );

        uint256 rewardIndex = $.rewardPeriods.length - 1;

        emit RewardAdded(
            rewardIndex, tokens, totalAmounts, merkleRoot
        );
    }

    /// @inheritdoc IClaim
    function claimRewards(RewardVerificationData[] calldata claims)
        external
        whenNotPaused
    {
        Storage.Layout storage $ = Storage.layout();

        for (uint256 i = 0; i < claims.length; i++) {
            RewardVerificationData calldata claim = claims[i];

            if (isClaimed(msg.sender, claim.rewardIndex)) {
                revert Claim_RewardAlreadyClaimed();
            }

            bytes32 merkleRoot =
                $.rewardPeriods[claim.rewardIndex].root;

            bytes32 leaf = keccak256(
                abi.encodePacked(msg.sender, claim.rewardIndex)
            );

            if (!MerkleProof.verify(claim.proof, merkleRoot, leaf)) {
                revert Claim_InvalidMerkleProof();
            }

            _setClaimed(msg.sender, claim.rewardIndex);

            for (uint256 j = 0; j < claim.tokens.length; j++) {
                IERC20(claim.tokens[j]).safeTransfer(
                    msg.sender, claim.amounts[j]
                );
            }
        }

        emit RewardsClaimed(msg.sender, claims);
    }

    /// @inheritdoc IClaim
    function withdrawTokens(address token, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokensWithdrawn(token, amount);
    }

    /// @inheritdoc IClaim
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IClaim
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IClaim
    function isClaimed(address user, uint256 rewardIndex)
        public
        view
        returns (bool claimed)
    {
        return Storage.layout().claimed[_hashClaimData(
            user, rewardIndex
        )];
    }

    /// @inheritdoc IClaim
    function getRewardPeriodData(uint256 rewardIndex)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            bytes32 merkleRoot
        )
    {
        RewardData storage rewardPeriod =
            Storage.layout().rewardPeriods[rewardIndex];
        return (
            rewardPeriod.tokens,
            rewardPeriod.totalAmounts,
            rewardPeriod.root
        );
    }

    /// @dev sets a user's claim status to true for a given reward period
    function _setClaimed(address user, uint256 rewardIndex)
        internal
    {
        Storage.layout().claimed[_hashClaimData(user, rewardIndex)] =
            true;
    }

    /// @dev hashes the reward index and token index into a bytes32
    function _hashClaimData(address user, uint256 rewardIndex)
        internal
        pure
        returns (bytes32 claimKey)
    {
        return keccak256(abi.encode(user, rewardIndex));
    }
}
