// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {W3KAssetsImpl, W3KAssetsBaseTypes} from "./W3KAssets.sol";
import {Version} from "../../utils/Version.sol";


contract W3KERC1155 is W3KAssetsImpl, ERC1155, Version {
    using Strings for address;
    using Strings for uint256;

    mapping(uint256=>bool) public mintedId;

    constructor() ERC1155(""){
        initRoles(address(0), address(0));
    }

    modifier notMinted(uint256 tokenId) {
        require(!mintedId[tokenId], "token id already minted");
        mintedId[tokenId] = true;
        _;
    }

    modifier wasMinted(uint256 tokenId) {
        require(mintedId[tokenId], "token id not minted");
        _;
    }

    function getType() public pure override returns(W3KAssetsBaseTypes.AssetsTypes) {
        return W3KAssetsBaseTypes.AssetsTypes.ERC1155;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(metadata.baseUri, "/", address(this).toHexString(), "/", tokenId.toString()));
    }

    function name() public view returns(string memory) {
        return metadata.name;
    }

    function symbol() public view returns(string memory) {
        return metadata.symbol;
    }

    function setBaseURI(string calldata _newUri) onlyExecutor external {
        emit BaseURIChange(metadata.baseUri, _newUri);
        metadata.baseUri = _newUri;
    }

    function mint(address to, uint256 amount, uint256 w3kId) onlyExecutor notMinted(nextTokenId) external {
        emit TokenMint(to, nextTokenId, amount, w3kId);
        _mint(to, nextTokenId, amount, "");
        mintedId[nextTokenId] = true;
        nextTokenId += 1;
    }

    function mint(address to, uint256 tokenId, uint256 amount, uint256 w3kId) onlyExecutor notMinted(tokenId) external {
        require(tokenId >= nextTokenId, "The specified token id must be greater or equal than the next automatic casting sequence id");
        emit TokenMint(to, tokenId, amount, w3kId);
        _mint(to, tokenId, amount, "");
        mintedId[tokenId] = true;
    }

    function issuance(address to, uint256 tokenId, uint256 amount) onlyExecutor wasMinted(tokenId) external {
        emit TokenIssuance(to, tokenId, amount);
        _mint(to, tokenId, amount, "");
    }

    function updateNextTokenId(uint256 newStart) onlyExecutor external {
        require(newStart > nextTokenId, "The new start token id must be greater than the next automatic casting sequence id");
        emit NewTokenIdStart(newStart);
        nextTokenId = newStart;
    }

    function burn(uint256 tokenId, uint256 amount) external {
        emit TokenBurn(msg.sender, tokenId, amount);
        _burn(msg.sender, tokenId, amount);
    }
}
