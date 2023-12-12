// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IW3KRolesV1 {
    event RolesInitialized(address owner, address executor);
    event ChangeOwner(address oldOwner, address newOwner);
    event AddExecutor(address executor);
    event RemoveExecutor(address executor);
}

contract W3KRolesV1 is IW3KRolesV1 {
    bool private initialized;

    address public owner;
    mapping(address=>bool) internal executor;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyExecutor() {
        require(executor[msg.sender], "not executor");
        _;
    }

    function initRoles(address _owner, address _executor) internal {
        require(!initialized, "already initialized");

        owner = _owner;

        //owner was always an executor
        executor[owner] = true;
        executor[_executor] = true;

        emit RolesInitialized(_owner, _executor);
    }

    function changeOwner(address _newOwner) onlyOwner external  {
        emit ChangeOwner(owner, _newOwner);

        //remove old owner's executor permission
        removeExecutor(owner);

        //assign new owner;
        owner = _newOwner;

        //set new owner as executor
        executor[_newOwner] = true;
    }

    function isExecutor(address addr) external view returns(bool) {
        return executor[addr];
    }

    function addExecutor(address addr) public onlyOwner {
        emit AddExecutor(addr);
        executor[addr] = true;
    }

    function removeExecutor(address addr) public onlyOwner {
        emit RemoveExecutor(addr);
        executor[addr] = false;
    }
}
