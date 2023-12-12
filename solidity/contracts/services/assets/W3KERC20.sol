// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {W3KAssetsImpl, W3KAssetsBaseTypes} from "./W3KAssets.sol";
import {Version} from "../../utils/Version.sol";

contract W3KERC20 is W3KAssetsImpl, ERC20, Version {
    bool public mintable;
    bool public burnable;

    bool internal erc20Initialized = false;

    constructor() ERC20("", "") {
        initRoles(address(0), address(0));
    }

    function getType() public pure override returns(W3KAssetsBaseTypes.AssetsTypes) {
        return W3KAssetsBaseTypes.AssetsTypes.ERC20;
    }

    function initERC20(W3KAssetsBaseTypes.ERC20InitParam calldata param) external {
        require(!erc20Initialized, "already initialized");
        erc20Initialized = true;

        _mint(owner, param.initSupply);

        metadata.decimals = param.decimals;
        mintable = param.mintable;
        burnable = param.burnable;
    }

    function name() public view override returns(string memory) {
        return metadata.name;
    }

    function symbol() public view override returns(string memory) {
        return metadata.symbol;
    }

    function decimals() public view override returns(uint8) {
        return metadata.decimals;
    }

    function mint(address to, uint256 amount) onlyExecutor external {
        require(mintable, "none-mintable token");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        require(burnable, "none-burnable token");
        _burn(msg.sender, amount);
    }
}
