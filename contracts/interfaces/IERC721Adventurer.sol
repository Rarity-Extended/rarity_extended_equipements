// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Adventurer {
    function ownerOf(uint256 tokenId) external view returns (uint);
    function getApproved(uint256 tokenId) external view returns (uint);
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
    function transferFrom(uint from, uint to, uint256 tokenId) external;
}