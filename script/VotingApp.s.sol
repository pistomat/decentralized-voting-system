// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/VotingApp.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract VotingAppDeployScript is Script {
    using Strings for address;

    // Used by default when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    bytes32 public initcodeHash; // 0x27e3e0ce62b0ab5c4b46db005e8522fd126ab3dbd7464ac458323fcffbdc8a67
    bytes32 public salt = bytes32(
        uint256(
            93076765818446630062842105350318295339817907742914462332510771001037203705471
        )
    );
    address public precomputedAddress =
        0x0000363AeF5c879eFf0339725989D7953BE35716;

    function setUp() public {
        initcodeHash = hashInitCode(type(VotingApp).creationCode);
        console2.log("VotingApp creation code hash: %x", uint256(initcodeHash));
    }

    function run() public {
        string[2][] memory rpcUrls = vm.rpcUrls();
        // assertEq(rpcUrls[0][0], "goerli");
        // assertEq(rpcUrls[1][0], "sepolia");
        // assertEq(rpcUrls[2][0], "polygon");

        require(rpcUrls.length == 3, "Must have 3 chains");
        require(
            keccak256(abi.encodePacked(rpcUrls[0][0]))
                == keccak256(abi.encodePacked("goerli")),
            "First chain must be Goerli"
        );
        require(
            keccak256(abi.encodePacked(rpcUrls[1][0]))
                == keccak256(abi.encodePacked("polygon")),
            "Second chain must be Polygon"
        );
        require(
            keccak256(abi.encodePacked(rpcUrls[2][0]))
                == keccak256(abi.encodePacked("sepolia")),
            "Third chain must be Sepolia"
        );

        for (uint256 i = 0; i < rpcUrls.length; i++) {
            vm.createSelectFork(rpcUrls[i][1]);
            deploy();
        }
    }

    function deploy() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        VotingApp votingApp = new VotingApp{salt: salt}();
        vm.stopBroadcast();

        require(
            uint8(votingApp.electionPhase())
                == uint8(VotingApp.ElectionPhase.Registration),
            "Election phase must be Registration"
        );
        require(
            address(votingApp)
                == computeCreate2Address({ salt: salt, initCodeHash: initcodeHash }),
            string.concat(
                "Created address ",
                address(votingApp).toHexString(),
                " must match precomputed address from fn ",
                precomputedAddress.toHexString(),
                "."
            )
        );

        require(
            address(votingApp) == precomputedAddress,
            string.concat(
                "Created address ",
                address(votingApp).toHexString(),
                " must match precomputed address from me",
                precomputedAddress.toHexString(),
                "."
            )
        );
    }
}
