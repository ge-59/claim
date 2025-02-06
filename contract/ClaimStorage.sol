// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import { RewardData } from "./Types.sol";
import { EnumerableSet } from
    "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title ClaimStorage
/// @dev storage library to leverage unstructured storage pattern
library ClaimStorage {
    /// @dev struct containing all state for the Claim contract
    struct Layout {
        /// @dev the reward data for each reward period
        RewardData[] rewardPeriods;
        /// claim key is hash of (user address + reward index)
        mapping(bytes32 claimKey => bool isClaimed) claimed;
    }

    // keccak256(abi.encode(uint256(keccak256("animoca.contracts.storage.Claim")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 internal constant STORAGE_SLOT =
        0x9e8f4dc20d46e2f43b0abc3bfc5e9fef5ad91ef5a3e7e2d4b7e16f7e3e2e3e00; //FAKE

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
