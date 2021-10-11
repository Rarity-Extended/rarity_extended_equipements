// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IRarity.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Adventurer.sol";

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
    
    struct Equipement {
        uint tokenID;
        address codex;
        address token;
        bool fromAdventurer;
    }
    mapping(uint => Equipement) public actionable_item;
    mapping(uint => Equipement) public armor;
    mapping(uint => Equipement) public primary_weapon;
    mapping(uint => Equipement) public secondary_weapon;
    mapping(uint => Equipement) public neck_jewelry;
    mapping(uint => Equipement) public belt_jewelry;
    mapping(uint => Equipement) public left_hand_jewelry;
    mapping(uint => Equipement) public right_hand_jewelry;
    mapping(uint => Equipement) public shield;


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
