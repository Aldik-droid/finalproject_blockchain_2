// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AssemblyMath} from "../../src/utils/AssemblyMath.sol";

contract AssemblyRevertWrapper {
    function divZeroAsm() external pure {
        AssemblyMath.mulDivAssembly(1, 1, 0);
    }

    function divZeroSol() external pure {
        AssemblyMath.mulDivSolidity(1, 1, 0);
    }
}

contract AssemblyRevertTest is Test {
    AssemblyRevertWrapper w = new AssemblyRevertWrapper();

    function test_AssemblyDivZeroReverts() public {
        vm.expectRevert(bytes("div0"));
        w.divZeroAsm();
    }

    function test_SolidityDivZeroReverts() public {
        vm.expectRevert(bytes("motion"));
        w.divZeroSol();
    }
}
