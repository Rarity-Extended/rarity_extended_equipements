// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRarity {
    function summon(uint _class) external;
    function getApproved(uint) external view returns (address);
    function next_summoner() external view returns (uint);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint _summoner) external view returns (address);
}
