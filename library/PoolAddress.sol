//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x6ce8eb472fa82df5469c6ab6d485f17c3ad13c8cd7af59b3d4a8026c5ce0f7e2;
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) internal pure returns (PoolKey memory) {
        if (_tokenA > _tokenB) {
            (_tokenA, _tokenB) = (_tokenB, _tokenA);
        }
        PoolKey memory poolKey = PoolKey(_tokenA, _tokenB, _fee);
        return poolKey;
    }

    function computeAddress(
        address deployer,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            deployer,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
