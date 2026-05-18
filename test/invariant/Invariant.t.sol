// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ConstantProductAMM} from "../../src/amm/ConstantProductAMM.sol";
import {ProtocolToken} from "../../src/tokens/ProtocolToken.sol";
import {YieldVault4626} from "../../src/vault/YieldVault4626.sol";
import {Treasury} from "../../src/Treasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvariantHandler is Test {
    ConstantProductAMM amm;
    ProtocolToken t0;
    ProtocolToken t1;
    address user = address(0xA11CE);

    constructor(ConstantProductAMM amm_, ProtocolToken a, ProtocolToken b, address admin) {
        amm = amm_;
        t0 = a;
        t1 = b;
        vm.startPrank(admin);
        t0.mint(user, 1e30);
        t1.mint(user, 1e30);
        vm.stopPrank();
        vm.startPrank(user);
        t0.approve(address(amm), type(uint256).max);
        t1.approve(address(amm), type(uint256).max);
        amm.addLiquidity(1000 ether, 1000 ether, 0, 0);
        vm.stopPrank();
    }

    function swap0(uint256 amt) external {
        amt = bound(amt, 1, 100 ether);
        vm.startPrank(user);
        amm.swapExactTokensForTokens(amt, 0, true, user);
        vm.stopPrank();
    }

    function swap1(uint256 amt) external {
        amt = bound(amt, 1, 100 ether);
        vm.startPrank(user);
        amm.swapExactTokensForTokens(amt, 0, false, user);
        vm.stopPrank();
    }
}

contract AMMInvariantTest is Test {
    ConstantProductAMM amm;
    ProtocolToken t0;
    ProtocolToken t1;
    InvariantHandler handler;
    uint256 kInitial;

    function setUp() public {
        t0 = new ProtocolToken(address(this));
        t1 = new ProtocolToken(address(this));
        amm = new ConstantProductAMM(address(t0), address(t1), address(this));
        handler = new InvariantHandler(amm, t0, t1, address(this));
        (uint256 r0, uint256 r1) = amm.getReserves();
        kInitial = r0 * r1;
        targetContract(address(handler));
    }

    function invariant_KNeverDecreases() public view {
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertGe(r0 * r1, kInitial);
    }

    function invariant_ReservesPositive() public view {
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
    }
}

contract VaultInvariantTest is Test {
    YieldVault4626 vault;
    ProtocolToken asset;

    function setUp() public {
        asset = new ProtocolToken(address(this));
        vault = new YieldVault4626(IERC20(address(asset)), address(this));
        asset.mint(address(this), 1e24);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1000 ether, address(this));
    }

    function invariant_SharesLteSupply() public view {
        assertLe(vault.balanceOf(address(this)), vault.totalSupply());
    }

    function invariant_TotalAssetsGteBalance() public view {
        assertGe(vault.totalAssets(), asset.balanceOf(address(vault)));
    }
}

contract TreasuryInvariantTest is Test {
    Treasury treasury;
    ProtocolToken token;

    function setUp() public {
        treasury = new Treasury(address(this));
        token = new ProtocolToken(address(this));
    }

    function invariant_PendingLteBalance() public view {
        uint256 pending = treasury.pendingWithdrawals(address(token), address(this));
        assertLe(pending, token.balanceOf(address(treasury)) + pending);
    }
}
