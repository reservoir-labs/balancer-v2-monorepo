// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";

/**
 * @dev This module provides an interface to store seemingly unrelated pieces of information in the same storage slot,
 * in particular to be used by Weighted Pools with a price oracle.
 *
 * These pieces of information are all kept together in a single storage slot to reduce the number of storage accesses.
 * We not only store configuration values (such as whether the oracle is enabled), but also cache reduced-precision
 * versions of the total BPT supply and invariant, which lets us not access nor compute these values when producing
 * oracle updates during a swap.
 *
 * Data is stored with the following structure, which is compatible with BasePool's misc data field as the upper 64 bits
 * are reserved.
 *
 * [ reserved | unused  | oracle enabled | oracle index | oracle sample initial timestamp | log supply | log invariant ]
 * [  uint64  | uint106 |     bool       |    uint10    |              uint31             |    int22   |     int22     ]
 */
library OracleWeightedPoolMiscData {
    using WordCodec for bytes32;
    using WordCodec for uint256;

    uint256 private constant _LOG_INVARIANT_OFFSET = 0;
    uint256 private constant _LOG_TOTAL_SUPPLY_OFFSET = 22;
    uint256 private constant _ORACLE_SAMPLE_CREATION_TIMESTAMP_OFFSET = 44;
    uint256 private constant _ORACLE_INDEX_OFFSET = 75;
    uint256 private constant _ORACLE_ENABLED_OFFSET = 85;

    /**
     * @dev Returns the cached logarithm of the invariant.
     */
    function logInvariant(bytes32 data) internal pure returns (int256) {
        return data.decodeInt(_LOG_INVARIANT_OFFSET, 22);
    }

    /**
     * @dev Returns the cached logarithm of the total supply.
     */
    function logTotalSupply(bytes32 data) internal pure returns (int256) {
        return data.decodeInt(_LOG_TOTAL_SUPPLY_OFFSET, 22);
    }

    /**
     * @dev Returns the timestamp of the creation of the oracle's latest sample.
     */
    function oracleSampleCreationTimestamp(bytes32 data) internal pure returns (uint256) {
        return data.decodeUint(_ORACLE_SAMPLE_CREATION_TIMESTAMP_OFFSET, 31);
    }

    /**
     * @dev Returns the index of the oracle's latest sample.
     */
    function oracleIndex(bytes32 data) internal pure returns (uint256) {
        return data.decodeUint(_ORACLE_INDEX_OFFSET, 10);
    }

    /**
     * @dev Returns true if the oracle is enabled.
     */
    function oracleEnabled(bytes32 data) internal pure returns (bool) {
        return data.decodeBool(_ORACLE_ENABLED_OFFSET);
    }

    /**
     * @dev Sets the logarithm of the invariant in `data`, returning the updated value.
     */
    function setLogInvariant(bytes32 data, int256 _logInvariant) internal pure returns (bytes32) {
        return data.insertInt(_logInvariant, _LOG_INVARIANT_OFFSET, 22);
    }

    /**
     * @dev Sets the logarithm of the total supply in `data`, returning the updated value.
     */
    function setLogTotalSupply(bytes32 data, int256 _logTotalSupply) internal pure returns (bytes32) {
        return data.insertInt(_logTotalSupply, _LOG_TOTAL_SUPPLY_OFFSET, 22);
    }

    /**
     * @dev Sets the timestamp of the creation of the oracle's latest sample in `data`, returning the updated value.
     */
    function setOracleSampleCreationTimestamp(bytes32 data, uint256 _initialTimestamp) internal pure returns (bytes32) {
        return data.insertUint(_initialTimestamp, _ORACLE_SAMPLE_CREATION_TIMESTAMP_OFFSET, 31);
    }

    /**
     * @dev Sets the index of the  oracle's latest sample in `data`, returning the updated value.
     */
    function setOracleIndex(bytes32 data, uint256 _oracleIndex) internal pure returns (bytes32) {
        return data.insertUint(_oracleIndex, _ORACLE_INDEX_OFFSET, 10);
    }

    /**
     * @dev Enables or disables the oracle in `data`, returning the updated value.
     */
    function setOracleEnabled(bytes32 data, bool _oracleEnabled) internal pure returns (bytes32) {
        return data.insertBool(_oracleEnabled, _ORACLE_ENABLED_OFFSET);
    }
}
