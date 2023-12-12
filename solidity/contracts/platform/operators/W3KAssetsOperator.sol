// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "../W3KCashier.sol";
import "../../services/assets/W3KAssets.sol";
import "../../services/assets/W3KERC20.sol";
import "../../services/assets/W3KERC721.sol";
import "../../services/assets/W3KERC1155.sol";

contract W3KAssetsOperator is W3KWithCashier {
    bool public enabled = false;
    
    enum ServiceCategory {
        PLACEHOLDER,
        MintERC20,
        MintERC721,
        MintERC1155,
        IssuanceERC1155
    }

    constructor(W3KCashier _cashier) W3KWithCashier(_cashier) {
        enabled = true;
    }

    modifier Enabled() {
        require(enabled, "not enabled for now");
        _;
    }

    function requireCheck(
        W3KAssetsImpl _assets,
        W3KAssetsBaseTypes.AssetsTypes _requireType
    ) view internal {
        address owner = _assets.owner();
        W3KAssetsBaseTypes.AssetsTypes aType = _assets.getType();

        require(owner == msg.sender, "not owner of assets contract");
        require(aType == _requireType, "invalid assets contract type");
    }

    function chargeFee(ServiceCategory category) internal {
        if(address(cashier) == address(0)) {
            return;
        }
        cashier.chargeFee{value: msg.value}(payable(msg.sender), uint256(category));
    }

    function mintERC20(W3KERC20 _assets, address _to, uint256 _amount) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC20);
        _assets.mint(_to, _amount);

        chargeFee(ServiceCategory.MintERC20);
    }

    function mintERC721(W3KERC721 _assets, address _to, uint256 _w3kId) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC721);
        _assets.mint(_to, _w3kId);

        chargeFee(ServiceCategory.MintERC721);
    }

    function mintERC721WithTokenId(
        W3KERC721 _assets, address _to, uint256 _tokenId, uint256 _w3kId
    ) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC721);
        _assets.mint(_to, _tokenId, _w3kId);

        chargeFee(ServiceCategory.MintERC721);
    }

    function mintERC1155(
        W3KERC1155 _assets, address _to, uint256 _amount, uint256 _w3kId
    ) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC1155);
        _assets.mint(_to, _amount, _w3kId);

        chargeFee(ServiceCategory.MintERC1155);
    }

    function mintERC1155WithTokenId(
        W3KERC1155 _assets,
        address _to, uint256 _tokenId, uint256 _amount, uint256 _w3kId
    ) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC1155);
        _assets.mint(_to, _tokenId, _amount, _w3kId);

        chargeFee(ServiceCategory.MintERC1155);
    }

    function issuanceERC1155(
        W3KERC1155 _assets,
        address _to, uint256 _tokenId, uint256 _amount
    ) Enabled external payable {
        requireCheck(_assets, W3KAssetsBaseTypes.AssetsTypes.ERC1155);
        _assets.issuance(_to, _tokenId, _amount);

        chargeFee(ServiceCategory.IssuanceERC1155);
    }
}
