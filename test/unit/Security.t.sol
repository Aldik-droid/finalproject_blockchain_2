// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReentrancyVulnerableVault, ReentrancyFixedVault} from "../../src/security/ReentrancyCaseStudy.sol";
import {AccessControlVulnerable, AccessControlFixed} from "../../src/security/AccessControlCaseStudy.sol";
import {ProtocolToken} from "../../src/tokens/ProtocolToken.sol";

contract SecurityTest is Test {
    function test_AccessControlAnyoneSetsFee() public {
        AccessControlVulnerable v = new AccessControlVulnerable();
        vm.prank(address(0xBEEF));
        v.setFee(9999);
        assertEq(v.feeBps(), 9999);
    }

    function test_AccessControlFixedReverts() public {
        AccessControlFixed f = new AccessControlFixed(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        f.setFee(100);
    }

    function test_AccessControlFixedAdmin() public {
        AccessControlFixed f = new AccessControlFixed(address(this));
        f.setFee(50);
        assertEq(f.feeBps(), 50);
    }

    function test_ReentrancyVulnerableDoubleSpend() public {
        ProtocolToken t = new ProtocolToken(address(this));
        ReentrancyVulnerableVault v = new ReentrancyVulnerableVault();
        ReentrancyAttacker atk = new ReentrancyAttacker(v, t);
        t.mint(address(atk), 100 ether);
        vm.prank(address(atk));
        t.approve(address(v), 100 ether);
        vm.prank(address(atk));
        v.deposit(address(t), 10 ether);
        vm.expectRevert();
        atk.attack(10 ether);
    }

    function test_ReentrancyFixedBlocks() public {
        ProtocolToken t = new ProtocolToken(address(this));
        ReentrancyFixedVault v = new ReentrancyFixedVault();
        t.mint(address(this), 100 ether);
        t.approve(address(v), 100 ether);
        v.deposit(address(t), 10 ether);
        v.withdraw(address(t), 10 ether);
        assertEq(v.balances(address(this)), 0);
    }
}

contract ReentrancyAttacker {
    ReentrancyVulnerableVault vault;
    ProtocolToken token;
    uint256 count;

    constructor(ReentrancyVulnerableVault v, ProtocolToken t) {
        vault = v;
        token = t;
    }

    function attack(uint256 amt) external {
        vault.withdraw(address(token), amt);
    }

    function onWithdraw() external {
        if (count++ < 2) vault.withdraw(address(token), 1 ether);
    }
}
