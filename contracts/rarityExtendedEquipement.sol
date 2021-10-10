// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IRarity.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Adventurer.sol";
import "./interfaces/IRarityItemSource.sol";
import "./interfaces/IRarityCodexArmor.sol";
import "./interfaces/IRarityCodexWeapon.sol";

contract rarity_extended_equipement_base is ERC721Holder {
    IRarity constant _rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    address public EXTENDED = address(0x0f5861aaf5F010202919C9126149c6B0c76Cf469);
    string constant public name = "Rarity Extended Equipement";
    uint public manager;
    mapping(address => address[5]) public codexes; // address => [item_codex, armor_codex, weapon_codex, jewelry_codex]

    modifier onlyExtended() {
		require (msg.sender == EXTENDED, "!owner");
		_;
	}
    
    /**
    **  @dev Check if the _owner has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **	@param _operator: the operator to check
    **/
    function _isApprovedOrOwner(uint _adventurer, address _operator) internal view returns (bool) {
        return (_rm.getApproved(_adventurer) == _operator || _rm.ownerOf(_adventurer) == _operator || _rm.isApprovedForAll(_rm.ownerOf(_adventurer), _operator));
    }

    /**
    **  @dev Check if the _owner has the autorization to act on this tokenID
    **	@param _tokenID: TokenID of the item we want to check
    **	@param _source: address of contract for tokenID 
    **/
    function _isApprovedOrOwnerOfItem(uint _tokenID, IERC721 _source, address _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_source.ownerOf(_tokenID), _operator)
        );
    }

    function _isApprovedOrOwnerOfItem(uint256 _tokenID, IERC721Adventurer _source, uint _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_tokenID, _operator)
        );
    }

}

contract rarity_extended_armor is rarity_extended_equipement_base {
    struct Armor {
        uint tokenID;
        address codex;
        address token;
        bool fromAdventurer;
    }

    mapping(uint => Armor) public armor;

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

        armor[_adventurer] = Armor(_tokenID, _codex, _tokenSource, false);
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

        armor[_adventurer] = Armor(_tokenID, _codex, _codex, false);
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

        armor[_adventurer] = Armor(_tokenID, _codex, _token, true);
        IERC721Adventurer(_token).transferFrom(_adventurer, manager, _tokenID);
    }
    
    function unset_armor(uint _adventurer) external {
        require(_isApprovedOrOwner(_adventurer, msg.sender));

        Armor memory _armor = armor[_adventurer];
        require(_armor.token != address(0), "!noArmor");

        armor[_adventurer] = Armor(0, address(0), address(0), false);
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

contract rarity_extended_primaryWeapon {
    struct Weapon {
        uint tokenID;
        address codex;
        address token;
        bool fromAdventurer;
    }

    mapping(uint => Weapon) public primary_weapon;

}

contract rarity_extended_equipement is rarity_extended_armor, rarity_extended_primaryWeapon {

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
        require(_source != address(0));
        require(codexes[_source][0] == address(0));
        codexes[_source][0] = _source;
        codexes[_source][1] = _item;
        codexes[_source][2] = _armor;
        codexes[_source][3] = _weapon;
        codexes[_source][4] = _jewelry;
    }

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
        Armor memory _armor = armor[_adventurer];
        (,uint8 item_type,,) = IRarityItemSource(_armor.codex).items(_armor.tokenID);
        address armorCodex = codexes[_armor.codex][2];
        return (IRarityCodexArmor(armorCodex).item_by_id(item_type));
    }
}