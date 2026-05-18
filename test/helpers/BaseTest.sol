// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeFiGovToken} from "../../src/tokens/DeFiGovToken.sol";
import {ProtocolToken} from "../../src/tokens/ProtocolToken.sol";
import {LPPositionNFT} from "../../src/tokens/LPPositionNFT.sol";
import {ConstantProductAMM} from "../../src/amm/ConstantProductAMM.sol";
import {LendingPool} from "../../src/lending/LendingPool.sol";
import {YieldVault4626} from "../../src/vault/YieldVault4626.sol";
import {MockChainlinkAggregator} from "../../src/oracle/MockChainlinkAggregator.sol";
import {PriceOracle} from "../../src/oracle/PriceOracle.sol";
import {PoolFactory} from "../../src/factory/PoolFactory.sol";
import {Treasury} from "../../src/Treasury.sol";
import {DeFiGovernor} from "../../src/governance/DeFiGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProtocolRegistryV1} from "../../src/upgradeable/ProtocolRegistryV1.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseTest is Test {
    address internal admin = makeAddr("admin");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal liquidator = makeAddr("liquidator");

    DeFiGovToken govToken;
    ProtocolToken token0;
    ProtocolToken token1;
    LPPositionNFT lpNft;
    ConstantProductAMM amm;
    LendingPool lending;
    YieldVault4626 vault;
    MockChainlinkAggregator feed;
    PriceOracle oracle;
    PoolFactory factory;
    Treasury treasury;
    TimelockController timelock;
    DeFiGovernor governor;
    ProtocolRegistryV1 registry;

    function setUp() public virtual {
        vm.startPrank(admin);
        treasury = new Treasury(admin);
        govToken = new DeFiGovToken(address(treasury));
        token0 = new ProtocolToken(admin);
        token1 = new ProtocolToken(admin);
        lpNft = new LPPositionNFT(admin);
        feed = new MockChainlinkAggregator(8, 2000e8);
        oracle = new PriceOracle(address(feed), 3600, admin);
        amm = new ConstantProductAMM(address(token0), address(token1), admin);
        lending = new LendingPool(address(token0), address(token1), address(oracle), admin);
        vault = new YieldVault4626(IERC20(address(token0)), admin);
        factory = new PoolFactory(admin);

        address[] memory proposers = new address[](1);
        proposers[0] = admin;
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        timelock = new TimelockController(2 days, proposers, executors, admin);
        governor = new DeFiGovernor(govToken, timelock);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));

        ProtocolRegistryV1 impl = new ProtocolRegistryV1();
        bytes memory init = abi.encodeWithSelector(
            ProtocolRegistryV1.initialize.selector, admin, address(amm), address(lending), address(vault), address(treasury)
        );
        registry = ProtocolRegistryV1(address(new ERC1967Proxy(address(impl), init)));

        token0.mint(alice, 1_000_000 ether);
        token0.mint(bob, 1_000_000 ether);
        token1.mint(alice, 1_000_000 ether);
        token1.mint(bob, 1_000_000 ether);
        token0.mint(address(lending), 500_000 ether);
        token1.mint(address(lending), 500_000 ether);
        vm.stopPrank();
    }
}
