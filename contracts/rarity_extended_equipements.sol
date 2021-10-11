// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IRarityItemSource.sol";
import "./interfaces/IRarityCodexArmor.sol";
import "./interfaces/IRarityCodexWeapon.sol";
import "./rarity_extended_equipement.sol";

contract rarity_extended_equipements is rarity_extended_equipement {
    constructor() {
        EXTENDED = address(msg.sender);
        manager = _rm.next_summoner();
        _rm.summon(4);
    }

    function    registerCodex(
        address _source,
        address _item,
        address _armor,
        address _weapon,
        address _jewelry
    ) public onlyExtended() {
        require(_source != address(0), "!_source");
        require(codexes[_source][0] == address(0), "!already");
        codexes[_source][0] = _source;
        codexes[_source][1] = _item;
        codexes[_source][2] = _armor;
        codexes[_source][3] = _weapon;
        codexes[_source][4] = _jewelry;
    }

    function get_slots(uint8 _slot) public pure returns (string memory) {
        if (_slot == 1) {
            return "Actionable Item";
        } else if (_slot == 2) {
            return "Armor";
        } else if (_slot == 3) {
            return "Primary Weapon";
        } else if (_slot == 4) {
            return "Secondary Weapon";
        } else if (_slot == 5) {
            return "Jewelry (neck)";
        } else if (_slot == 6) {
            return "Jerwelry (belt)";
        } else if (_slot == 7) {
            return "Jewelry (left hand)";
        } else if (_slot == 8) {
            return "Jewelry (right hand)";
        } else if (_slot == 9) {
            return "Shield";
        }
        return "";
    }

    /* GETTERS */
    function get_armor(uint _adventurer) external view returns(
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        int,
        uint,
        string memory,
        string memory
    ) {
        Equipement memory _armor = armor[_adventurer];
        (,uint8 item_type,,) = IRarityItemSource(_armor.codex).items(_armor.tokenID);
        address armorCodex = codexes[_armor.codex][2];
        return (IRarityCodexArmor(armorCodex).item_by_id(item_type));
    }
    function get_shield(uint _adventurer) external view returns(
        uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        int,
        uint,
        string memory,
        string memory
    ) {
        Equipement memory _equipement = shield[_adventurer];
        (,uint8 item_type,,) = IRarityItemSource(_equipement.codex).items(_equipement.tokenID);
        address armorCodex = codexes[_equipement.codex][2];
        return (IRarityCodexArmor(armorCodex).item_by_id(item_type));
    }
}