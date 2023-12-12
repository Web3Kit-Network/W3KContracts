// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {W3KRolesV1} from "../../utils/W3KRoles.sol";

library W3KAssetsBaseTypes {
    enum AssetsTypes {
        PLACEHOLDER,
        ERC20,
        ERC721,
        ERC1155
    }

    struct InitParam {
        string name;
        string symbol;
        string baseUri;
    }

    struct ERC20InitParam {
        uint8 decimals;
        uint256 initSupply;
        bool mintable;
        bool burnable;
    }

    struct Metadata {
        string name;
        string symbol;
        string baseUri;
        uint8 decimals;
        AssetsTypes assetsType;
    }
}

contract W3KAssets is W3KRolesV1 {
    event W3KAssetsInitialized(address assets, address owner, address operator, W3KAssetsBaseTypes.Metadata metadata);
    event BaseURIChange(string oldUri, string newUri);
    event TokenMint(address to, uint256 tokenId, uint256 amount, uint256 w3kId);
    event TokenBurn(address owner, uint256 tokenId, uint256 amount);
    event TokenIssuance(address to, uint256 tokenId, uint256 amount);
    event NewTokenIdStart(uint256 newStart);

    bool private initialized;
    W3KAssetsBaseTypes.Metadata internal metadata;
    uint256 public nextTokenId;

    function _initialize(
        address _owner,
        address _operator,
        W3KAssetsBaseTypes.InitParam calldata _param,
        W3KAssetsBaseTypes.AssetsTypes assetsType
    ) internal {
        require(!initialized, "already initialized");
        initialized = true;

        //initialize roles of this contract
        initRoles(_owner, _operator);

        metadata.name = _param.name;
        metadata.symbol = _param.symbol;
        metadata.baseUri = _param.baseUri;
        metadata.decimals = 0;
        metadata.assetsType = assetsType;

        nextTokenId = 1;

        emit W3KAssetsInitialized(address(this), _owner, _operator, metadata);
    }
}

abstract contract W3KAssetsImpl is W3KAssets {
    function getType() public pure virtual returns(W3KAssetsBaseTypes.AssetsTypes);

    function initialize(
        address owner, address operator,
        W3KAssetsBaseTypes.InitParam calldata param
    ) external {
        super._initialize(owner, operator, param, getType());
    }
}

