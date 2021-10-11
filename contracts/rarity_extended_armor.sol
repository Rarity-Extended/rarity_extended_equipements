// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./rarity_extended_equipement_base.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Adventurer.sol";
import "./interfaces/IRarityItemSource.sol";

contract rarity_extended_armor is rarity_extended_equipement_base {
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
    function set_armor(uint _adventurer, address _operator, address _codex, address _tokenSource, uint256 _tokenID) external {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_tokenSource), msg.sender), "!equipement"); 

        (uint8 base_type,,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == 2, "!armor");
        require(armor[_adventurer].token == address(0), "!already");

        armor[_adventurer] = Equipement(_tokenID, _codex, _tokenSource, false);
        IERC721(_tokenSource).safeTransferFrom(_operator, address(this), _tokenID);
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
    **	@param _codex: address of the contract that hold the items + the mapping, aka with which we will interact to transfer the item
    **	@param _tokenID: the tokenID of the armor
    **/ 
    function set_armor(uint _adventurer, address _operator, address _codex, uint256 _tokenID) external {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_codex), msg.sender), "!equipement"); 

        (uint8 base_type,,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == 2, "!armor");
        require(armor[_adventurer].token == address(0), "!already");

        armor[_adventurer] = Equipement(_tokenID, _codex, _codex, false);
        IERC721(_codex).safeTransferFrom(_operator, address(this), _tokenID);
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
    function set_armor(uint _adventurer, uint _operator, address _codex, address _token, uint256 _tokenID) external {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721Adventurer(_token), _operator), "!equipement"); 
        
        (uint8 base_type,,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == 2, "!armor");
        require(armor[_adventurer].token == address(0), "!already");

        armor[_adventurer] = Equipement(_tokenID, _codex, _token, true);
        IERC721Adventurer(_token).transferFrom(_adventurer, manager, _tokenID);
    }
    
    function unset_armor(uint _adventurer) external {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");

        Equipement memory _armor = armor[_adventurer];
        require(_armor.token != address(0), "!noArmor");

        armor[_adventurer] = Equipement(0, address(0), address(0), false);
        if (_armor.fromAdventurer) {
            IERC721Adventurer(_armor.token).transferFrom(
                manager,
                _adventurer,
                _armor.tokenID
            );
        } else {
            IERC721(_armor.token).safeTransferFrom(
                address(this),
                _rm.ownerOf(_adventurer),
                _armor.tokenID
            );
        }
    }
}
