// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {W3KRolesV1} from "../utils/W3KRoles.sol";

contract W3KCashier is W3KRolesV1, ReentrancyGuard {
    using Strings for address;
    using Address for address payable;

    struct ChargeSetting {
        bool exists;
        address currency;
        uint256 amount;
        address payable recipient;
    }

    struct SettingCategory {
        bool exist;
        mapping(uint256=>ChargeSetting) category;
    }

    event ChangeDefaultRecipient(address oldRecipient, address newRecipient);
    event FeeCharged(address service, address payer, uint256 amount, ChargeSetting setting);
    event FreeService(address service);
    event ChargeZero(address service, address payer, ChargeSetting setting);
    event FeeInfoSet(address service, ChargeSetting setting);
    event FeeInfoRemoved(address service, ChargeSetting setting);

    address payable public defaultRecipient;
    mapping(address=>SettingCategory) internal chargeSettings;

    constructor(address payable recipient) ReentrancyGuard() {
        initRoles(msg.sender, msg.sender);
        defaultRecipient = recipient;
    }

    function updateDefaultRecipient(address payable newRecipient) onlyOwner external {
        emit ChangeDefaultRecipient(defaultRecipient, newRecipient);
        defaultRecipient = newRecipient;
    }

    function deleteFeeSetting(address service, uint256 cid) onlyExecutor external {
        SettingCategory storage serviceSettings = chargeSettings[service];
        if(!serviceSettings.exist) {
            revert("service not exist");
        }

        serviceSettings.category[cid].exists = false;
        emit FeeInfoRemoved(service, serviceSettings.category[cid]);
    }

    function updateFeeSetting(address service, uint256 cid, ChargeSetting memory setting) onlyExecutor external {
        require(service.code.length > 0, "only live contract can charge fee!");
        if(setting.recipient == address(0)) {
            setting.recipient = defaultRecipient;
        }
        SettingCategory storage serviceSettings = chargeSettings[service];
        serviceSettings.exist = true;

        setting.exists = true;
        serviceSettings.category[cid] = setting;

        emit FeeInfoSet(service, setting);
    }

    function getSetting(
        address service,
        uint256 category
    ) public view returns(ChargeSetting memory setting, bool exist) {
        SettingCategory storage serviceSettings = chargeSettings[service];
        if(!serviceSettings.exist) {
            return (setting, false);
        }

        setting = serviceSettings.category[category];

        return (setting, setting.exists);
    }

    function chargeFee(address payable payer, uint256 category) nonReentrant external payable {
        (ChargeSetting memory setting, bool exist) = getSetting(msg.sender, category);
        uint256 refundETH = msg.value;

        if(!exist) {
            emit FreeService(msg.sender);
            if(refundETH != 0) {
                //eth refund if it's a free service
                payer.sendValue(refundETH);
            }
            return;
        }

        require(setting.recipient != address(0), "invalid recipient");
        if(setting.amount == 0) {
            emit ChargeZero(msg.sender, payer, setting);
            if(refundETH != 0) {
                //eth refund if charge zero
                payer.sendValue(refundETH);
            }
            return;
        }

        uint256 feeAmount = setting.amount;
        uint256 inAmount = msg.value;
        if(setting.currency != address(0)) {
            IERC20 currency = IERC20(setting.currency);
            inAmount = currency.allowance(payer, address(this));
        }
        require(feeAmount <= inAmount, "invalid fixed amount charge amount");

        if(setting.currency == address(0)) {
            setting.recipient.sendValue(feeAmount);
            refundETH = inAmount - feeAmount;
        } else {
            IERC20 currency = IERC20(setting.currency);
            uint256 payerBalance = currency.balanceOf(payer);
            require(
                payerBalance >= feeAmount,
                string(abi.encodePacked("insufficient token ", setting.currency.toHexString()," balance")));

            currency.transferFrom(payer, setting.recipient, feeAmount);
        }

        if(refundETH != 0) {
            payer.sendValue(refundETH);
        }

        emit FeeCharged(msg.sender, payer, feeAmount, setting);
    }
}

contract W3KWithCashier is W3KRolesV1 {
    event SetCashier(W3KCashier oldCashier, W3KCashier newCashier);

    W3KCashier public cashier;

    constructor(W3KCashier _cashier) {
        initRoles(msg.sender, msg.sender);
        cashier = _cashier;
    }

    function updateCashier(W3KCashier _cashier) external onlyOwner {
        emit SetCashier(cashier, _cashier);
        cashier = _cashier;
    }
}
