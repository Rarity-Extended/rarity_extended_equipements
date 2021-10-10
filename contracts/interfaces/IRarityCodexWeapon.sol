// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRarityCodexWeapon {
    function item_by_id(uint _id) external pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint encumbrance,
        uint damage_type,
        uint weight,
        uint damage,
        uint critical,
        int critical_modifier,
        uint range_increment,
        string memory name,
        string memory description
    );
}