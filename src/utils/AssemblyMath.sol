// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Yul assembly implementations benchmarked against Solidity equivalents.
library AssemblyMath {
    function mulDivAssembly(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        require(denominator != 0, "div0");
        assembly {
            let prod := mul(x, y)
            result := div(prod, denominator)
        }
    }

    function mulDivSolidity(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        require(denominator != 0, "motion");
        return (x * y) / denominator;
    }
}
