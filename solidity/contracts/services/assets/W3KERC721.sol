// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {W3KAssetsImpl, W3KAssetsBaseTypes} from "./W3KAssets.sol";
import {Version} from "../../utils/Version.sol";

contract W3KERC721 is W3KAssetsImpl, ERC721, Version {
    using Strings for address;

    mapping(uint256=>bool) public minted;

    constructor() ERC721("", "") {
        initRoles(address(0), address(0));
    }

    modifier notMinted(uint256 _tokenId) {
        require(!minted[_tokenId], "already minted");
        _;
    }

    function getType() public pure override returns(W3KAssetsBaseTypes.AssetsTypes) {
        return W3KAssetsBaseTypes.AssetsTypes.ERC721;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return string(abi.encodePacked(metadata.baseUri, "/", address(this).toHexString(), "/"));
    }

    function name() public view override returns(string memory) {
        return metadata.name;
    }

    function symbol() public view override returns(string memory) {
        return metadata.symbol;
    }

    function setBaseURI(string calldata _newUri) onlyExecutor external {
        emit BaseURIChange(metadata.baseUri, _newUri);
        metadata.baseUri = _newUri;
    }

    function mint(address to, uint256 w3kId) onlyExecutor notMinted(nextTokenId) external {
        emit TokenMint(to, nextTokenId, 1, w3kId);
        _safeMint(to, nextTokenId);
        minted[nextTokenId] = true;
        nextTokenId += 1;
    }

    function mint(address to, uint256 tokenId, uint256 w3kId) onlyExecutor notMinted(tokenId) external {
        require(tokenId >= nextTokenId, "The specified token id must be greater or equal than the next automatic casting sequence id");
        emit TokenMint(to, tokenId, 1, w3kId);
        minted[tokenId] = true;
        _safeMint(to, tokenId);
    }

    function updateNextTokenId(uint256 newStart) onlyExecutor external {
        require(newStart > nextTokenId, "The new start token id must be greater than the next automatic casting sequence id");
        emit NewTokenIdStart(newStart);
        nextTokenId = newStart;
    }

    function burn(uint256 tokenId) external {
        emit TokenBurn(_ownerOf(tokenId), tokenId, 1);
        _burn(tokenId);
    }
}
