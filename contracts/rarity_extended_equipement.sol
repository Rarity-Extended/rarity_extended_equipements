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
            head[_adventurer] = _equipement;
        } else if (_slot == 2) {
            body[_adventurer] = _equipement;
        } else if (_slot == 3) {
            hand[_adventurer] = _equipement;
        } else if (_slot == 4) {
            foot[_adventurer] = _equipement;
        } else if (_slot == 5) {
            primary_weapon[_adventurer] = _equipement;
        } else if (_slot == 6) {
            secondary_weapon[_adventurer] = _equipement;
        } else if (_slot == 7) {
            first_jewelry[_adventurer] = _equipement;
        } else if (_slot == 8) {
            second_jewelry[_adventurer] = _equipement;
        } else if (_slot == 9) {
            shield[_adventurer] = _equipement;
        }
    }
    function _get_slot(uint _slot, uint _adventurer) internal view returns (Equipement memory) {
         if (_slot == 1) {
            return head[_adventurer];
        } else if (_slot == 2) {
            return body[_adventurer];
        } else if (_slot == 3) {
            return hand[_adventurer];
        } else if (_slot == 4) {
            return foot[_adventurer];
        } else if (_slot == 5) {
            return primary_weapon[_adventurer];
        } else if (_slot == 6) {
            return secondary_weapon[_adventurer];
        } else if (_slot == 7) {
            return first_jewelry[_adventurer];
        } else if (_slot == 8) {
            return second_jewelry[_adventurer];
        } else if (_slot == 9) {
            return shield[_adventurer];
        }
        return Equipement(0, address(0), false);
    }
    function _isValidBaseType(uint _baseType, uint _slot) internal pure returns (bool) {
        if (_baseType <= 1)
            return false;
        if (_baseType == 2 && (_slot > 4 || _slot != 9))
            return false;
        if (_baseType == 3 && (_slot != 5 || _slot != 6))
            return false;
        if (_baseType == 4 && (_slot != 7 || _slot != 8))
            return false;
        return true;
    }
    function _handle_specific_situations(
        uint _adventurer,
        address _codex,
        uint8 _slot,
        uint8 _base_type,
        uint8 _item_type
    ) internal view {
        //If item is armor and not trying to equip shield
        if (_base_type == 2 && _slot != 9) {
            (,,uint proficiency,,,,,,,) = IRarityCodexArmor(_codex).item_by_id(_item_type);
            require(proficiency != 4, "shield"); //Then item should not be a shield
        }


        //If item is armor and trying to equip shield
       else if (_base_type == 2 && _slot == 9) {
            (,,uint proficiency,,,,,,,) = IRarityCodexArmor(_codex).item_by_id(_item_type);
            require(proficiency == 4, "!shield"); //Then item should be a shield

            //If a weapon is already equiped in slot 6 (secondary_weapon), revert
            require(secondary_weapon[_adventurer].registry == address(0), "!already_weapon");

            //Require primary weapon is not two handed or ranged
            Equipement memory _primary_weapon = primary_weapon[_adventurer];
            address codex = registries[_primary_weapon.registry].codex;
            (,uint8 item_type,,) = IRarityItemSource(_primary_weapon.registry).items(_primary_weapon.tokenID);
            IRarityCodexWeapon.IWeapon memory _weapon = IRarityCodexWeapon(codex).item_by_id(item_type);
            require(_weapon.encumbrance < 4, "!encumbrance");
        }

        
        //If item is secondary weapon, should fail if shield or two handed/ranged primary
        else if (_base_type == 3 && _slot == 6) {
            //If a shield is already equiped in slot 9 (shields), revert
            require(shield[_adventurer].registry == address(0), "!already_shield");

            //Require primary weapon is not two handed or ranged
            Equipement memory _primary_weapon = primary_weapon[_adventurer];
            address codex = registries[_primary_weapon.registry].codex;
            (,uint8 item_type,,) = IRarityItemSource(_primary_weapon.registry).items(_primary_weapon.tokenID);
            IRarityCodexWeapon.IWeapon memory _weapon = IRarityCodexWeapon(codex).item_by_id(item_type);
            require(_weapon.encumbrance < 4, "!encumbrance");
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
    **	@param _registry: address of the contract from which is generated the ERC721
    **	@param _tokenID: the tokenID of equipement
    **/ 
    function set_equipement(uint _adventurer, address _operator, address _registry, uint256 _tokenID) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_registry), msg.sender), "!equipement"); 

        Registry memory registry = registries[_registry];
        require(registry.slot > 0, "!registry");

        (uint8 base_type, uint8 item_type,,) = IRarityItemSource(registry.codex).items(_tokenID);
        require(_isValidBaseType(base_type, registry.slot), "!base_type");
        _handle_specific_situations(_adventurer, registry.codex, registry.slot, base_type, item_type);
        require(_get_slot(registry.slot, _adventurer).registry == address(0), "!already");

        _assign_equipement(registry.slot, _adventurer, Equipement(_tokenID, _registry, false));
        IERC721(_registry).safeTransferFrom(_operator, address(this), _tokenID);
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
    function set_equipement(uint _adventurer, uint _operator, address _registry, uint256 _tokenID) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721Adventurer(_registry), _operator), "!equipement"); 
        
        Registry memory registry = registries[_registry];
        require(registry.slot > 0, "!registry");

        (uint8 base_type, uint8 item_type,,) = IRarityItemSource(registry.codex).items(_tokenID);
        require(_isValidBaseType(base_type, registry.slot), "!base_type");
        _handle_specific_situations(_adventurer, registry.codex, registry.slot, base_type, item_type);
        require(_get_slot(registry.slot, _adventurer).registry == address(0), "!already");

        _assign_equipement(registry.slot, _adventurer, Equipement(_tokenID, _registry, true));
        IERC721Adventurer(_registry).transferFrom(_adventurer, manager, _tokenID);
    }
    
    function unset_equipement(uint _adventurer, uint8 _slot) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");

        Equipement memory _equipement = _get_slot(_slot, _adventurer);
        require(_equipement.registry != address(0), "!noArmor");

        _assign_equipement(_slot, _adventurer, Equipement(0, address(0), false));
        if (_equipement.fromAdventurer) {
            IERC721Adventurer(_equipement.registry).transferFrom(
                manager,
                _adventurer,
                _equipement.tokenID
            );
        } else {
            IERC721(_equipement.registry).safeTransferFrom(
                address(this),
                _rm.ownerOf(_adventurer),
                _equipement.tokenID
            );
        }
    }
}
