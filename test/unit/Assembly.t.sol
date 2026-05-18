// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AssemblyMath} from "../../src/utils/AssemblyMath.sol";

contract AssemblyTest is Test {
    function test_MulDivEquivalence() public pure {
        assertEq(AssemblyMath.mulDivAssembly(100, 200, 50), AssemblyMath.mulDivSolidity(100, 200, 50));
    }

    function test_MulDivLarge() public pure {
        uint256 r1 = AssemblyMath.mulDivAssembly(1e18, 1e18, 1e18);
        uint256 r2 = AssemblyMath.mulDivSolidity(1e18, 1e18, 1e18);
        assertEq(r1, r2);
    }

    function test_GasBenchmark() public {
        uint256 gasAsm;
        uint256 gasSol;
        uint256 x = 123456789;
        uint256 y = 987654321;
        uint256 d = 1000;
        gasAsm = gasleft();
        AssemblyMath.mulDivAssembly(x, y, d);
        gasAsm -= gasleft();
        gasSol = gasleft();
        AssemblyMath.mulDivSolidity(x, y, d);
        gasSol -= gasleft();
        assertTrue(gasAsm > 0 && gasSol > 0);
    }
}
