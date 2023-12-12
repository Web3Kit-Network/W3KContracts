// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {W3KRolesV1} from "./W3KRoles.sol";

contract W3KProxy is W3KRolesV1, ERC1967Proxy {
    constructor(address impl, address owner, address executor) ERC1967Proxy(impl, bytes("")) {
        initRoles(owner, executor);
    }

    receive() external payable {
        revert("ETH mis-transfer in");
    }
}
