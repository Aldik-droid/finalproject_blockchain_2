// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DeFiGovToken} from "../src/tokens/DeFiGovToken.sol";
import {ProtocolToken} from "../src/tokens/ProtocolToken.sol";
import {LPPositionNFT} from "../src/tokens/LPPositionNFT.sol";
import {ConstantProductAMM} from "../src/amm/ConstantProductAMM.sol";
import {LendingPool} from "../src/lending/LendingPool.sol";
import {YieldVault4626} from "../src/vault/YieldVault4626.sol";
import {MockChainlinkAggregator} from "../src/oracle/MockChainlinkAggregator.sol";
import {PriceOracle} from "../src/oracle/PriceOracle.sol";
import {PoolFactory} from "../src/factory/PoolFactory.sol";
import {Treasury} from "../src/Treasury.sol";
import {DeFiGovernor} from "../src/governance/DeFiGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProtocolRegistryV1} from "../src/upgradeable/ProtocolRegistryV1.sol";

/// @notice Idempotent deployment script for L2 testnets (Base Sepolia default).
contract Deploy is Script {
    uint256 public constant TIMELOCK_DELAY = 2 days;
    uint256 public constant MAX_STALENESS = 3600;

    struct Deployment {
        address govToken;
        address protocolToken;
        address lpNft;
        address amm;
        address lending;
        address vault;
        address oracle;
        address feed;
        address factory;
        address treasury;
        address timelock;
        address governor;
        address registry;
    }

    function run() external returns (Deployment memory d) {
        address deployer = msg.sender;
        vm.startBroadcast();

        d.treasury = address(new Treasury(deployer));
        d.govToken = address(new DeFiGovToken(d.treasury));
        d.protocolToken = address(new ProtocolToken(deployer));
        d.lpNft = address(new LPPositionNFT(deployer));

        d.feed = address(new MockChainlinkAggregator(8, 2000e8));
        d.oracle = address(new PriceOracle(d.feed, MAX_STALENESS, deployer));

        ProtocolToken pt = ProtocolToken(d.protocolToken);
        address weth = address(new ProtocolToken(deployer)); // second asset for pair demo

        d.amm = address(new ConstantProductAMM(d.protocolToken, weth, deployer));
        d.lending = address(new LendingPool(d.protocolToken, weth, d.oracle, deployer));
        d.vault = address(new YieldVault4626(pt, deployer));
        d.factory = address(new PoolFactory(deployer));

        address[] memory proposers;
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        d.timelock = address(new TimelockController(TIMELOCK_DELAY, proposers, executors, deployer));
        d.governor = address(new DeFiGovernor(DeFiGovToken(d.govToken), TimelockController(payable(d.timelock))));

        TimelockController tl = TimelockController(payable(d.timelock));
        tl.grantRole(tl.PROPOSER_ROLE(), d.governor);
        tl.grantRole(tl.CANCELLER_ROLE(), d.governor);
        tl.grantRole(tl.EXECUTOR_ROLE(), address(0));

        ProtocolRegistryV1 impl = new ProtocolRegistryV1();
        bytes memory init = abi.encodeWithSelector(
            ProtocolRegistryV1.initialize.selector, deployer, d.amm, d.lending, d.vault, d.treasury
        );
        d.registry = address(new ERC1967Proxy(address(impl), init));

        vm.stopBroadcast();

        _log(d);
        _writeDeploymentJson(d);
    }

    function _log(Deployment memory d) internal pure {
        console2.log("=== DeFi Super-App deployment ===");
        console2.log("DeFiGovToken", d.govToken);
        console2.log("ProtocolToken", d.protocolToken);
        console2.log("LPPositionNFT", d.lpNft);
        console2.log("ConstantProductAMM", d.amm);
        console2.log("LendingPool", d.lending);
        console2.log("YieldVault4626", d.vault);
        console2.log("PriceOracle", d.oracle);
        console2.log("MockChainlinkAggregator", d.feed);
        console2.log("PoolFactory", d.factory);
        console2.log("Treasury", d.treasury);
        console2.log("TimelockController", d.timelock);
        console2.log("DeFiGovernor", d.governor);
        console2.log("ProtocolRegistry", d.registry);
    }

    function _writeDeploymentJson(Deployment memory d) internal {
        string memory path = "deployments/out";
        vm.serializeUint(path, "chainId", block.chainid);
        string memory network = block.chainid == 84532 ? "base-sepolia" : vm.toString(block.chainid);
        vm.serializeString(path, "network", network);
        string memory contracts = "contracts";
        vm.serializeAddress(contracts, "DeFiGovToken", d.govToken);
        vm.serializeAddress(contracts, "ProtocolToken", d.protocolToken);
        vm.serializeAddress(contracts, "LPPositionNFT", d.lpNft);
        vm.serializeAddress(contracts, "ConstantProductAMM", d.amm);
        vm.serializeAddress(contracts, "LendingPool", d.lending);
        vm.serializeAddress(contracts, "YieldVault4626", d.vault);
        vm.serializeAddress(contracts, "PriceOracle", d.oracle);
        vm.serializeAddress(contracts, "MockChainlinkAggregator", d.feed);
        vm.serializeAddress(contracts, "PoolFactory", d.factory);
        vm.serializeAddress(contracts, "Treasury", d.treasury);
        vm.serializeAddress(contracts, "TimelockController", d.timelock);
        vm.serializeAddress(contracts, "DeFiGovernor", d.governor);
        string memory inner = vm.serializeAddress(contracts, "ProtocolRegistry", d.registry);
        string memory root = vm.serializeString(path, "contracts", inner);
        vm.writeJson(root, "deployments/base-sepolia.json");
        console2.log("Wrote deployments/base-sepolia.json");
    }
}
