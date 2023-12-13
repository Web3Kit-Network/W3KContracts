// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import {W3KRolesV1} from "../../utils/W3KRoles.sol";
import {W3KAssetsImpl, W3KAssetsBaseTypes} from "../../services/assets/W3KAssets.sol";
import {W3KERC20} from "../../services/assets/W3KERC20.sol";
import {Version} from "../../utils/Version.sol";
import "../../utils/W3KProxy.sol";

contract W3KAssetsFactory is W3KRolesV1, Version {
    using Strings for uint256;

    event AssetsContractCreated(
        address owner, address delegator,
        W3KAssetsBaseTypes.AssetsTypes assetsType,
        W3KAssetsBaseTypes.InitParam initParam,
        W3KAssetsBaseTypes.ERC20InitParam erc20InitParam
    );
    event ChangeCommonBaseUri(string oldUri, string newUri);
    event ChangeOperator(address oldOperator, address newOperator);

    mapping(W3KAssetsBaseTypes.AssetsTypes=>address) public assetsImpls;
    mapping(address=>W3KAssetsBaseTypes.AssetsTypes) public proxyTypes;

    address public operator;

    string internal commonBaseUri = "";

    constructor(string memory baseUri, address optAddr) {
        initRoles(msg.sender, msg.sender);
        commonBaseUri = string(abi.encodePacked(baseUri, "/", block.chainid.toString()));
        operator = optAddr;
    }

    function deployAssetsContract(
        W3KAssetsBaseTypes.AssetsTypes _type,
        W3KAssetsBaseTypes.InitParam memory _param,
        W3KAssetsBaseTypes.ERC20InitParam calldata _erc20Param
    ) external {
        require(operator != address(0), "operator not set yet");
        require(_type != W3KAssetsBaseTypes.AssetsTypes.PLACEHOLDER, "invalid type");

        //replace param's baseUri with commonBaseUri
        _param.baseUri = commonBaseUri;

        address impl = assetsImpls[_type];
        W3KProxy newProxy = new W3KProxy(impl, msg.sender, operator);
        address proxyAddr = address(newProxy);
        proxyTypes[proxyAddr] = _type;

        W3KAssetsImpl(proxyAddr).initialize(msg.sender, address(proxyAddr), _param);
        if(_type == W3KAssetsBaseTypes.AssetsTypes.ERC20) {
            W3KERC20(proxyAddr).initERC20(_erc20Param);
        }

        emit AssetsContractCreated(msg.sender, operator, _type, _param, _erc20Param);
    }

    function updateImpl(W3KAssetsBaseTypes.AssetsTypes _type, address _implAddr) onlyExecutor external {
        require(_type != W3KAssetsBaseTypes.AssetsTypes.PLACEHOLDER, "invalid type");
        assetsImpls[_type] = _implAddr;
    }

    function updateCommonBaseUri(string calldata _newUri) onlyExecutor external {
        emit ChangeCommonBaseUri(commonBaseUri, _newUri);
        commonBaseUri = _newUri;
    }

    function updateOperator(address _newOpt) onlyExecutor external {
        emit ChangeOperator(operator, _newOpt);
        operator = _newOpt;
    }
}
