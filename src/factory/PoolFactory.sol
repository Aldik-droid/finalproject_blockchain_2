// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ConstantProductAMM} from "../amm/ConstantProductAMM.sol";

/// @notice Factory deploying AMM pools via CREATE and CREATE2 (Factory pattern).
contract PoolFactory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    address[] public allPools;
    mapping(address => mapping(address => address)) public getPool;
    mapping(bytes32 => address) public getPoolBySalt;

    event PoolCreated(address indexed token0, address indexed token1, address pool, bool deterministic);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, admin);
    }

    /// @dev CREATE deployment — address depends on factory nonce.
    function createPool(address token0, address token1) external onlyRole(DEPLOYER_ROLE) returns (address pool) {
        require(token0 != token1, "identical");
        (address t0, address t1) = token0 < token1 ? (token0, token1) : (token1, token0);
        require(getPool[t0][t1] == address(0), "exists");

        ConstantProductAMM newPool = new ConstantProductAMM(t0, t1, address(this));
        pool = address(newPool);
        getPool[t0][t1] = pool;
        getPool[t1][t0] = pool;
        allPools.push(pool);
        emit PoolCreated(t0, t1, pool, false);
    }

    /// @dev CREATE2 deployment — address depends on salt + init code hash.
    function createPoolDeterministic(address token0, address token1, bytes32 salt)
        external
        onlyRole(DEPLOYER_ROLE)
        returns (address pool)
    {
        require(token0 != token1, "identical");
        (address t0, address t1) = token0 < token1 ? (token0, token1) : (token1, token0);
        require(getPoolBySalt[salt] == address(0), "salt used");

        bytes memory bytecode = abi.encodePacked(type(ConstantProductAMM).creationCode, abi.encode(t0, t1, address(this)));
        assembly {
            pool := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(pool != address(0), "create2 failed");
        getPool[t0][t1] = pool;
        getPool[t1][t0] = pool;
        getPoolBySalt[salt] = pool;
        allPools.push(pool);
        emit PoolCreated(t0, t1, pool, true);
    }

    function poolsLength() external view returns (uint256) {
        return allPools.length;
    }
}
