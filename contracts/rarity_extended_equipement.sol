// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./rarity_extended_equipement_base.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Adventurer.sol";
import "./interfaces/IRarityItemSource.sol";
import "./interfaces/IRarityCodexArmor.sol";
import "./interfaces/IRarityCodexWeapon.sol";

contract rarity_extended_equipement is rarity_extended_equipement_base {
    function _assign_equipement(uint8 _slot, uint _adventurer, Equipement memory _equipement) internal {
         if (_slot == 1) {
            actionable_item[_adventurer] = _equipement;
        } else if (_slot == 2) {
            armor[_adventurer] = _equipement;
        } else if (_slot == 3) {
            primary_weapon[_adventurer] = _equipement;
        } else if (_slot == 4) {
            secondary_weapon[_adventurer] = _equipement;
        } else if (_slot == 5) {
            neck_jewelry[_adventurer] = _equipement;
        } else if (_slot == 6) {
            belt_jewelry[_adventurer] = _equipement;
        } else if (_slot == 7) {
            left_hand_jewelry[_adventurer] = _equipement;
        } else if (_slot == 8) {
            right_hand_jewelry[_adventurer] = _equipement;
        } else if (_slot == 9) {
            shield[_adventurer] = _equipement;
        }
    }
    function _get_slot(uint _slot, uint _adventurer) internal view returns (Equipement memory) {
        if (_slot == 1) {
            return actionable_item[_adventurer];
        } else if (_slot == 2) {
            return armor[_adventurer];
        } else if (_slot == 3) {
            return primary_weapon[_adventurer];
        } else if (_slot == 4) {
            return secondary_weapon[_adventurer];
        } else if (_slot == 5) {
            return neck_jewelry[_adventurer];
        } else if (_slot == 6) {
            return belt_jewelry[_adventurer];
        } else if (_slot == 7) {
            return left_hand_jewelry[_adventurer];
        } else if (_slot == 8) {
            return right_hand_jewelry[_adventurer];
        } else if (_slot == 9) {
            return shield[_adventurer];
        }
        return Equipement(0, address(0), address(0), false);
    }
    function _get_base_type(uint _slot) internal pure returns (uint8) {
        if (_slot == 1) {
            return 1;
        } else if (_slot == 2) {
            return 2;
        } else if (_slot == 3) {
            return 3;
        } else if (_slot == 4) {
            return 3;
        } else if (_slot == 5) {
            return 4;
        } else if (_slot == 6) {
            return 4;
        } else if (_slot == 7) {
            return 4;
        } else if (_slot == 8) {
            return 4;
        } else if (_slot == 9) {
            return 2;
        }
        return 0;
    }
    function _handle_specific_situations(
        uint _adventurer,
        address _codex,
        uint8 _slot,
        uint8 _base_type,
        uint8 _item_type
    ) internal view {
        if (_slot == 1) {
        } else if (_slot == 2) {
            //Preventing a shield to be used as armor
            if (_base_type == 2) {
                address armorCodex = codexes[_codex][2];
                (,,uint proficiency,,,,,,,) = IRarityCodexArmor(armorCodex).item_by_id(_item_type);
                require(proficiency != 4, "shield");
            }
        } else if (_slot == 3) {
        } else if (_slot == 4) {
            //Preventing a secondary weapon if a shield is equipped
            require(_get_slot(9, _adventurer).token == address(0), "!already_shield");

            //Preventing a secondary if a primary two handed / ranged weapon is equiped
            if (_get_slot(3, _adventurer).token != address(0)) {
                Equipement memory _primary_weapon = primary_weapon[_adventurer];
                (,uint8 item_type,,) = IRarityItemSource(_primary_weapon.codex).items(_primary_weapon.tokenID);
                IRarityCodexWeapon.IWeapon memory _weapon = IRarityCodexWeapon(codexes[_primary_weapon.codex][3]).item_by_id(item_type);
                require(_weapon.encumbrance < 4, "!encumbrance");
            }
        } else if (_slot == 5) {
        } else if (_slot == 6) {
        } else if (_slot == 7) {
        } else if (_slot == 8) {
        } else if (_slot == 9) {
            //Preventing an armor to be used as shield
            if (_base_type == 2) {
                address armorCodex = codexes[_codex][2];
                (,,uint proficiency,,,,,,,) = IRarityCodexArmor(armorCodex).item_by_id(_item_type);
                require(proficiency == 4, "!shield");
            }

            //Preventing a shield if a secondary weapon is equipped
            require(_get_slot(4, _adventurer).token == address(0), "!already_weapon");

            //Preventing a shield if a primary two handed / ranged weapon is equiped
            if (_get_slot(3, _adventurer).token != address(0)) {
                Equipement memory _primary_weapon = primary_weapon[_adventurer];
                (,uint8 item_type,,) = IRarityItemSource(_primary_weapon.codex).items(_primary_weapon.tokenID);
                IRarityCodexWeapon.IWeapon memory _weapon = IRarityCodexWeapon(codexes[_primary_weapon.codex][3]).item_by_id(item_type);
                require(_weapon.encumbrance < 4, "!encumbrance");
            }
        }
    }

    /**
    **  @dev Assign an armor to an adventurer. If the adventurer already has an armor, it will revert.
    **  The owner of the adventurer must be the owner of the armor, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have to unset the armor
    **  before it can be transfered to another player.
    **  @notice line by line comments:
    **      - Can the msg.sender act for this adventurer?
    **      - Can the msg.sender use this equipement?
    **      - Retrieve the base type of the item from the _codex contract (2 for armors)
    **      - Revert if base_type is an armor
    **      - Revert if an armor is already equiped
    **      - Assign this new armor to the adventurer
    **      - Try to transfer the armor from the wallet of the _operator to this contract to lock it
    **
    **  @param _adventurer: the tokenID of the adventurer we want to assign the armor to
    **	@param _operator: address in which name we are acting for. This is msg.sender if the player directly call this contract
    **	@param _codex: address of the contract that hold the items mapping
    **	@param _tokenSource: address of the base contract for this item, aka with which we will interact to transfer the item
    **	@param _tokenID: the tokenID of the armor
    **/ 
    function set_equipement(
        uint _adventurer,
        address _operator,
        address _codex,
        address _tokenSource,
        uint256 _tokenID,
        uint8 _slot
    ) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_tokenSource), msg.sender), "!equipement"); 

        (uint8 base_type, uint8 item_type,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == _get_base_type(_slot), "!base_type");
        _handle_specific_situations(_adventurer, _codex, _slot, base_type, item_type);
        require(_get_slot(_slot, _adventurer).token == address(0), "!already");

        _assign_equipement(_slot, _adventurer, Equipement(_tokenID, _codex, _tokenSource, false));
        IERC721(_tokenSource).safeTransferFrom(_operator, address(this), _tokenID);
    }

    /**
    **  @dev Assign an armor to an adventurer. If the adventurer already has an armor, it will revert.
    **  The owner of the adventurer must be the owner of the armor, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have to unset the armor
    **  before it can be transfered to another player.
    **  @notice line by line comments:
    **      - Can the msg.sender act for this adventurer?
    **      - Can the _operator, which is an adventurer, act on this item?
    **      - Retrieve the base type of the item from the _codex contract (2 for armors)
    **      - Revert if base_type is an armor
    **      - Revert if an armor is already equiped
    **      - Assign this new armor to the adventurer
    **      - Try to transfer the armor from the wallet of the _operator to this contract to lock it
    **
    **  @param _adventurer: the tokenID of the adventurer we want to assign the armor to
    **	@param _operator: adventurer in which name we are acting for. This is _adventurer if the player directly call this contract
    **	@param _codex: address of the contract that hold the items mapping
    **	@param _tokenSource: address of the base contract for this item, aka with which we will interact to transfer the item
    **	@param _tokenID: the tokenID of the armor
    **/ 
    function set_equipement(
        uint _adventurer, 
        uint _operator, 
        address _codex, 
        address _token, 
        uint256 _tokenID,
        uint8 _slot
    ) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721Adventurer(_token), _operator), "!equipement"); 
        
        (uint8 base_type, uint8 item_type,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == _get_base_type(_slot), "!base_type");
        _handle_specific_situations(_adventurer, _codex, _slot, base_type, item_type);
        require(_get_slot(_slot, _adventurer).token == address(0), "!already");

        _assign_equipement(_slot, _adventurer, Equipement(_tokenID, _codex, _token, true));
        IERC721Adventurer(_token).transferFrom(_adventurer, manager, _tokenID);
    }
    
    function unset_equipement(uint _adventurer, uint8 _slot) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");

        Equipement memory _equipement = _get_slot(_slot, _adventurer);
        require(_equipement.token != address(0), "!noArmor");

        _assign_equipement(_slot, _adventurer, Equipement(0, address(0), address(0), false));
        if (_equipement.fromAdventurer) {
            IERC721Adventurer(_equipement.token).transferFrom(
                manager,
                _adventurer,
                _equipement.tokenID
            );
        } else {
            IERC721(_equipement.token).safeTransferFrom(
                address(this),
                _rm.ownerOf(_adventurer),
                _equipement.tokenID
            );
        }
    }
}
