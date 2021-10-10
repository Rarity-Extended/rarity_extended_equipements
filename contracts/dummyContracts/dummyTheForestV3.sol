//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ITheRarityForest {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function treasure(uint tokenId) external view returns (string memory _itemName, uint _magic, uint _level);
}
interface ITheRarityForestV2 {
    function transferFrom(uint from, uint to, uint256 tokenId) external;
    function treasure(uint tokenId) external view returns (uint _summonerId, string memory _itemName, uint _magic, uint _level);
    function ownerOf(uint256 tokenId) external view returns (uint owner);
}
interface IRarity {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
    function spend_xp(uint _summoner, uint _xp) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function next_summoner() external view returns (uint);
    function summon(uint _class) external;
}
interface IRarityXPProxy {
    function spend_xp(uint _summoner, uint _xp) external returns (bool);
}

/*
    This is a modified version of ERC721, updated to use UINT in ADDRESS. 
    In this case, we attach this NFT to another NFT.
    Note that uint(0) is equivalent to address(0), so holder of the first NFT is burner address and can't access to some functions in contract
*/

interface IERC721 {
    event Transfer(uint indexed from, uint indexed to, uint256 indexed tokenId);
    event Approval(uint indexed owner, uint indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(uint indexed owner, uint indexed operator, bool approved);
    function balanceOf(uint owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (uint owner);
    function transferFrom(
        uint from,
        uint to,
        uint256 tokenId
    ) external;
    function approve(uint from, uint to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (uint operator);
    function setApprovalForAll(uint from, uint operator, bool _approved) external;
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
}

contract ERC721 is IERC721 {
    using Strings for uint256;

    constructor(address _rarityAddr){
        rm = IRarity(_rarityAddr);
    }

    IRarity public rm;

    mapping(uint256 => uint) private _owners;
    mapping(uint => uint256) private _balances;
    mapping(uint256 => uint) private _tokenApprovals;
    mapping(uint => mapping(uint => bool)) private _operatorApprovals;

    function balanceOf(uint owner) public view virtual override returns (uint256) {
        require(owner != uint(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (uint) {
        uint owner = _owners[tokenId];
        require(owner != uint(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(uint from, uint to, uint256 tokenId) public virtual override {
        uint owner = ERC721.ownerOf(tokenId);
        require(_isApprovedOrOwnerOfSummoner(from), "not owner of summoner");

        require(
            from == owner || isApprovedForAll(owner, from),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (uint) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(uint from, uint operator, bool approved) public virtual override {
        require(operator != from, "ERC721: approve to caller");
        require(_isApprovedOrOwnerOfSummoner(from), "not owner of summoner");
        _operatorApprovals[from][operator] = approved;
        emit ApprovalForAll(from, operator, approved);
    }

    function isApprovedForAll(uint owner, uint operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        uint from,
        uint to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwnerOfSummoner(from), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != uint(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(uint spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        uint owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _isApprovedOrOwnerOfSummoner(uint _summoner) internal view returns (bool) {
        return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender || rm.isApprovedForAll(rm.ownerOf(_summoner), msg.sender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(uint to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter.
     */
    function _safeMint(
        uint to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(uint to, uint256 tokenId) internal virtual {
        require(to != uint(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(uint(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(uint(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        uint owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, uint(0), tokenId);

        // Clear approvals
        _approve(uint(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, uint(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        uint from,
        uint to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != uint(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(uint(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(uint to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        uint from,
        uint to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(uint owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    // Mapping from owner to list of owned token IDs
    mapping(uint => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(uint owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        uint from,
        uint to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == uint(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == uint(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(uint to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(uint from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}









/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract TheRarityForestV3 is ERC721Enumerable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor(address _rarityAddr, address _rarityForestAddr, address _rarityForestV2Addr, address _xpAddr) ERC721(_rarityAddr) {
        rarityContract = IRarity(_rarityAddr);
        rarityForestContract = ITheRarityForest(_rarityForestAddr);
        rarityForestContractV2 = ITheRarityForestV2(_rarityForestV2Addr);
        _xp = IRarityXPProxy(_xpAddr);
    }

    IRarity public rarityContract;
    ITheRarityForest public rarityForestContract;
    ITheRarityForestV2 public rarityForestContractV2;
    IRarityXPProxy public _xp;
    uint256 private globalSeed;
    string constant public name = "TheRarityForestV3";
    string constant public symbol = "TRFv3";
    mapping(uint256 => Research) researchs; //summonerId => Research
    mapping(uint256 => string) items;
    mapping(uint256 => uint256) magic;
    mapping(uint256 => uint256) level;
    Counters.Counter public _tokenIdCounter;
    address public rescuer;
    address constant EXTENDED = address(0x0f5861aaf5F010202919C9126149c6B0c76Cf469);

    string[] sevenDaysItems = [
        "Dead King crown", 
        "Black gauntlet",
        "Haunted ring",
        "Ancient book",
        "Enchanted book",
        "Gold ring",
        "Treasure map",
        "Spell book",
        "Silver sword",
        "Ancient Prince Andre's Sword",
        "Old damaged coin",
        "Magic necklace",
        "Mechanical hand"
    ];
    string[] sixDaysItems = [
        "Silver sword",
        "Haunted ring",
        "War helmet",
        "Fire boots",
        "War trophy",
        "Elf skull",
        "Unknown ring",
        "Silver ring",
        "War book",
        "Gold pot",
        "Demon head",
        "Unknown key",
        "Cursed book",
        "Giant plant seed",
        "Old farmer sickle",
        "War trophy",
        "Enchanted useless tool"
    ];
    string[] fiveDaysItems = [
        "Dragon egg",
        "Bear claw",
        "Silver sword",
        "Rare ring",
        "Glove with diamonds",
        "Haunted cloak",
        "Dead hero cape",
        "Cursed talisman",
        "Enchanted talisman",
        "Haunted ring",
        "Time crystal",
        "Warrior watch",
        "Paladin eye",
        "Metal horse saddle",
        "Witcher book",
        "Witch book",
        "Unknown animal eye"
    ];
    string[] fourDaysItems = [
        "Slain warrior armor",
        "Witcher book",
        "Cursed talisman",
        "Antique ring",
        "Ancient Prince Andre's Sword",
        "King's son sword",
        "Old damaged coin",
        "Thunder hammer",
        "Time crystal",
        "Skull fragment",
        "Hawk eye",
        "Meteorite fragment",
        "Mutant fisheye",
        "Wolf necklace",
        "Shadowy rabbit paw",
        "Paladin eye",
        "Red Tanned Gloves",
        "Paladin heart",
        "Cat Claw glove"
    ];

    event ResearchStarted(uint256 summonerId, uint256 initBlockTs, uint256 endBlockTs, uint256 timeInDays);
    event TreasureDiscovered(uint256 summonerId, uint256 treasureId);
    event TreasureLevelUp(uint256 treasureId, uint256 newLevel);

    struct Research {
        uint256 timeInDays;
        uint256 initBlockTs; //Block when research started
        bool discovered;
        uint256 summonerId;
        address owner;
        uint256 endBlockTs; //Block when research will end
    }

    struct Treasure {
        uint256 summonerId;
        uint256 treasureId;
        string itemName;
        uint256 magic;
        uint256 level;
    }

    modifier onlyExtended() {
		require (msg.sender == EXTENDED, "!owner");
		_;
	}

    //Set rescuer
    function setRescuer(address _rescuer) public {
        require(rescuer == address(0), "already setted");
        rescuer = _rescuer;
    }

    //Se XP proxy
    function setXPProxy(address newAddress) public onlyExtended() {
        _xp = IRarityXPProxy(newAddress);
    }

    //Gen random
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    //Return required XP to levelup a treasure
    function xpRequired(uint currentLevel) public pure returns (uint xpToNextLevel) {
        xpToNextLevel = currentLevel * 1000e18;
        for (uint i = 1; i < currentLevel; i++) {
            xpToNextLevel += currentLevel * 1000e18;
        }
    }

    //Get random treasure
    function _randomTreasure(Research memory research) internal returns (string memory _itemName, uint256 _magic, uint256 _level) {
        string memory _string = string(
            abi.encodePacked(
                research.summonerId, 
                research.owner, 
                research.initBlockTs, 
                globalSeed,
                block.timestamp
            )
        );
        uint256 index = _random(_string);
        globalSeed = index;

        _magic = index % 11;
        _level = index % 6;

        if (research.timeInDays == 7) {
            _itemName = sevenDaysItems[index % sevenDaysItems.length];
        }
        if (research.timeInDays == 6) {
            _itemName = sixDaysItems[index % sixDaysItems.length];
        }
        if (research.timeInDays == 5) {
            _itemName = fiveDaysItems[index % fiveDaysItems.length];
        }
        if (research.timeInDays == 4) {
            _itemName = fourDaysItems[index % fourDaysItems.length];
        }
        
    }

    //Is owner of summoner or is approved
    function _isApprovedOrOwnerOfSummoner(uint256 summonerId, address _owner) internal view virtual returns (bool) {
        //_owner => expected owner
        address spender = address(this);
        address owner = rarityContract.ownerOf(summonerId);
        return (owner == _owner || rarityContract.getApproved(summonerId) == spender || rarityContract.isApprovedForAll(owner, spender));
    }

    //Mint a new ERC721
    function safeMint(uint to) internal returns (uint256) {
        uint256 counter = _tokenIdCounter.current();
        _safeMint(to, counter, "");
        _tokenIdCounter.increment();
        return counter;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("name", " ", items[tokenId]));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(abi.encodePacked("magic", " ", magic[tokenId].toString()));

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = string(abi.encodePacked("level", " ", level[tokenId].toString()));

        parts[6] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "treasure #', tokenId.toString(), '", "description": "Rarity is achieved through good luck and intelligence", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    //Research for new treasuries
    function startResearch(uint256 summonerId, uint256 timeInDays) public returns (uint256) {
        //timeInDays -> time to research the forest
        require(timeInDays >= 4 && timeInDays <= 7, "not valid");
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your summoner");
        (,,,uint256 summonerLevel) = rarityContract.summoner(summonerId);
        require(summonerLevel >= 2, "not level >= 2");
        require(researchs[summonerId].timeInDays == 0 || researchs[summonerId].discovered == true, "not empty or not discovered yet"); //If empty or already discovered
        researchs[summonerId] = Research(timeInDays, block.timestamp, false, summonerId, msg.sender, block.timestamp + (timeInDays * 1 days));
        emit ResearchStarted(summonerId, researchs[summonerId].initBlockTs, researchs[summonerId].endBlockTs, timeInDays);
        return summonerId;
    }

    //Discover a treasure
    function discover(uint256 summonerId) public returns (uint256) {
        uint256 newTokenId = safeMint(summonerId);
		items[newTokenId] = 'Slain warrior armor';
		magic[newTokenId] = 1;
		level[newTokenId] = 2;
        emit TreasureDiscovered(summonerId, newTokenId);
        return newTokenId;
    }

    //Level up an item, spending summoner XP (need approval)
    function levelUp(uint256 tokenId) public {
        uint256 summonerId = ownerOf(tokenId);
        require(_isApprovedOrOwnerOfSummoner(summonerId, msg.sender), "not your treasure");
        uint256 current = level[tokenId];
        _xp.spend_xp(summonerId, xpRequired(current));
        level[tokenId] += 1;
        emit TreasureLevelUp(tokenId, current + 1);
    }

    //Get all treasures by summoner (adventurer)
    function getTreasuresBySummoner(uint256 summonerId) public view returns (Treasure[] memory) {
        require(summonerId != uint(0), "cannot retrieve zero address");
        uint256 arrayLength = balanceOf(summonerId);
        Treasure[] memory _treasures = new Treasure[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(summonerId, i);
            (uint256 _summonerId, string memory _itemName, uint _magic, uint _level) = treasure(tokenId);
            _treasures[i] = Treasure(_summonerId, tokenId ,_itemName, _magic, _level);
        }
        return _treasures;
    }

    //Get research status by summoner (if is in progress "discovered" bool is in FALSE)
    function getResearchBySummoner(uint256 summonerId) public view returns (Research memory) {
        require(summonerId != uint(0), "cannot retrieve zero address");
        return researchs[summonerId];
    }

    //Migrate treasure from V1 to V3
    function restoreTreasure(uint256 tokenId, uint256 receiver) public {
        require(receiver != uint(0), "receiver is zero address");
        rarityForestContract.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId); //Burn
        uint256 newTokenId = safeMint(receiver);
        (items[newTokenId], magic[newTokenId], level[newTokenId]) = rarityForestContract.treasure(tokenId);
    }

    //Save treasure from V2 to V3
    function saveTreasure(uint256 tokenId) public {
        require(msg.sender == rescuer, "not rescuer");
        uint owner = rarityForestContractV2.ownerOf(tokenId);
        uint256 newTokenId = safeMint(owner);
        (, items[newTokenId], magic[newTokenId], level[newTokenId]) = rarityForestContractV2.treasure(tokenId);
    }

    //View your treasure
    function treasure(uint tokenId) public view returns (uint256 _summonerId, string memory _itemName, uint _magic, uint _level) {
        _summonerId = ownerOf(tokenId);
        _itemName = items[tokenId];
        _magic = magic[tokenId];
        _level = level[tokenId];
    }

}