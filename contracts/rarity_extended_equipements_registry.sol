// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IRarityItemSource.sol";
import "./interfaces/IRarityCodexArmor.sol";
import "./interfaces/IRarityCodexWeapon.sol";
import "./rarity_extended_equipement.sol";

contract rarity_extended_equipements_registry is rarity_extended_equipement {
    constructor() {
        EXTENDED = address(msg.sender);
        manager = _rm.next_summoner();
        _rm.summon(4);
    }

    function    registerCodex(address _source, address _codex, uint8 _slot) public onlyExtended() {
        require(_source != address(0) && registries[_source].slot != 0, "!_source");
        require(_codex != address(0), "!codex");
        registries[_source] = registries(_codex, _slot);
    }

    function    get_slots(uint8 _slot) public pure returns (string memory) {
        if (_slot == 1) {
            return "Head";
        } else if (_slot == 2) {
            return "Body";
        } else if (_slot == 3) {
            return "Hand";
        } else if (_slot == 4) {
            return "Foot";
        } else if (_slot == 5) {
            return "Primary Weapon";
        } else if (_slot == 6) {
            return "Secondary Weapon";
        } else if (_slot == 7) {
            return "First Jewelry";
        } else if (_slot == 8) {
            return "Second Jewelry";
        } else if (_slot == 9) {
            return "Shield";
        }
        return "";
    }

    /* GETTERS */
    function    get_armor(uint _adventurer) external view returns(
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