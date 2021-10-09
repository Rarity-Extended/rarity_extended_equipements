// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IRarity {
    function summon(uint _class) external;
    function getApproved(uint) external view returns (address);
    function next_summoner() external view returns (uint);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint _summoner) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Adventurer {
    function ownerOf(uint256 tokenId) external view returns (uint);
    function getApproved(uint256 tokenId) external view returns (uint);
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
    function transferFrom(uint from, uint to, uint256 tokenId) external;
}

interface IRarityItemSource {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isValid(uint _base_type, uint _item_type) external pure returns (bool);
    function items(uint tokenID) external view returns (uint8 base_type, uint8 item_type, uint32 crafted, uint256 crafter);
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IRarityCodexArmor {
    function item_by_id(uint _id) external pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    );
}
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

contract rarity_extended_equipement is ERC721Holder {
    IRarity constant _rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    address public EXTENDED = address(0x0f5861aaf5F010202919C9126149c6B0c76Cf469);
    string constant public name = "Rarity Extended Equipement";
    uint public manager;

    modifier onlyExtended() {
		require (msg.sender == EXTENDED, "!owner");
		_;
	}

    struct Armor {
        uint tokenID;
        address codex;
        address token;
        bool fromAdventurer;
    }
    struct Weapon {
        uint tokenID;
        address source;
    }

    mapping(uint => Armor) private armor;
    mapping(uint => Weapon) private primary_weapon;
    mapping(uint => Weapon) private secondary_weapon;
    mapping(address => address[5]) private codexes; // address => [item_codex, armor_codex, weapon_codex, jewelry_codex]

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


    /**
    **  @dev Assign a weapon to an adventurer. If the adventurer already has a weapon, it will revert.
    **  The owner of the adventurer must be the owner of the weapon, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have to unset the weapon
    **  before it can be transfered to another player.
    **  In order to be sure that we are working with a weapon, we are using the `isValid` function. This
    **  function is defined in the `IRarityItemSource` interface and returns true if the item is a weapon.
    **  The weapon identifier, aka `_base_type` is `2` (`1` for items, `2` for armors, `3` for weapons), and 
    **  the item identifier aka `_item_type` can be retrieve from the source contract with the `items` function.
    **
    **  @param _adventurer: TokenID of the adventurer we want to assign the weapon to
    **	@param _owner: the owner to check
    **	@param _source: the source contract of the weapon
    **	@param _tokenID: the tokenID of the weapon
    **/ 
    // function set_weapon(uint _adventurer, address _operator, address _codexSource, address _token, uint256 _tokenID) external {
    //     require(_isApprovedOrOwner(_adventurer), "!owner");
    //     require(_isApprovedOrOwner(_adventurer, _operator), "!_operator");
    //     require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_token)), "!itemOwner");
        
    //     (uint8 base_type, uint8 item_type,,) = IRarityItemSource(_codexSource).items(_tokenID);
        
    //     //If a weapon is already assigned, revert
    //     Weapon memory _current_weapon = primary_weapon[_adventurer];
    //     require(_current_weapon.tokenID == 0, "This adventurer already has an weapon");

    //     //Assign the weapon to the adventurer
    //     primary_weapon[_adventurer] = Weapon(_tokenID, _codexSource);

    //     //Lock the armor in this contract
    //     IRarityItemSource(_token).safeTransferFrom(_operator, address(this), _tokenID);
    // }
    
    // function unset_weapon(uint _adventurer, address _recipient) external {
    //     require(_isApprovedOrOwner(_adventurer));
    //     Weapon memory _weapon = primary_weapon[_adventurer];
    //     IRarityItemSource(_weapon.source).safeTransferFrom(address(this), _recipient, _weapon.tokenID);
    //     primary_weapon[_adventurer] = Weapon(0, address(0));
    // }
    
    // function get_weapon(uint _adventurer) external view returns(
    //     uint id,
    //     uint cost,
    //     uint proficiency,
    //     uint encumbrance,
    //     uint damage_type,
    //     uint weight,
    //     uint damage,
    //     uint critical,
    //     int critical_modifier,
    //     uint range_increment,
    //     string memory weapon_name,
    //     string memory weapon_description
    // ) {
    //     Weapon memory _weapon = primary_weapon[_adventurer];
    //     address weaponCodex = codexes[_weapon.source][1];
    //     return (IRarityCodexWeapon(weaponCodex).item_by_id(_weapon.tokenID));
    // }   







    /**
    **  @dev Assign an armor to an adventurer. If the adventurer already has an armor, it will revert.
    **  The owner of the adventurer must be the owner of the armor, or it must be an approve address.
    **  The ERC721 is transfered to this contract, aka locked. The player will have to unset the armor
    **  before it can be transfered to another player.
    **  In order to be sure that we are working with an armor, we are using the `isValid` function. This
    **  function is defined in the `IRarityItemSource` interface and returns true if the item is an armor.
    **  The armor identifier, aka `_base_type` is `2` (`1` for items, `2` for armors, `3` for weapons), and 
    **  the item identifier aka `_item_type` can be retrieve from the source contract with the `items` function.
    **
    **  @param _adventurer: TokenID of the adventurer we want to assign the armor to
    **	@param _operator: the owner to check
    **	@param _source: the source contract of the armor
    **	@param _tokenID: the tokenID of the armor
    **/ 
    function set_armor(uint _adventurer, address _operator, address _codex, address _token, uint256 _tokenID) external {
        //Can the msg.sender act for this adventurer?
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        //can the msg.sender use this equipement?
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721(_token), msg.sender), "!equipement"); 
        

        (uint8 base_type,,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == 2, "!armor");
        
        //If an armor is already assigned, revert
        Armor memory _current_armor = armor[_adventurer];
        require(_current_armor.token == address(0), "!already");

        //Assign the armor to the adventurer
        armor[_adventurer] = Armor(_tokenID, _codex, _token, false);

        //Lock the armor in this contract
        IERC721(_token).safeTransferFrom(_operator, address(this), _tokenID);
    }

    function set_armor_by_adventure(uint _adventurer, uint _operator, address _codex, address _token, uint256 _tokenID) external {
        //Can the msg.sender act for this adventurer?
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        //can the msg.sender use this equipement?
        require(_isApprovedOrOwnerOfItem(_tokenID, IERC721Adventurer(_token), _operator), "!equipement"); 
        
        (uint8 base_type,,,) = IRarityItemSource(_codex).items(_tokenID);
        require(base_type == 2, "!armor");

        //If an armor is already assigned, revert
        Armor memory _current_armor = armor[_adventurer];
        require(_current_armor.token == address(0), "!already");

        //Assign the armor to the adventurer
        armor[_adventurer] = Armor(_tokenID, _codex, _token, true);

        //Lock the armor in this contract
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