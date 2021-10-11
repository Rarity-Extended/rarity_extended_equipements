/******************************************************************************
**	@Author:				Thomas Bouder <Tbouder>
**	@Email:					Tbouder@protonmail.com
**	@Date:					Monday October 11th 2021
**	@Filename:				00_basicTests copy.js
******************************************************************************/

require("dotenv").config();
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');
const { deployments, ethers } = require('hardhat');
const RarityExtendedEquipements = artifacts.require("rarity_extended_equipements");
const Dummy = artifacts.require("dummy");
const DummyArmorCodex = artifacts.require("dummy_codex_items_armor");

const DummyTheForest = artifacts.require("TheRarityForestV3");
const DummyTheForestItemsProxy = artifacts.require("theForestProxyItems");
const DummyTheForestGoodsCodex = artifacts.require("theForest_good_codex");
const DummyTheForestArmorCodex = artifacts.require("theForest_armor_codex");
const DummyTheForestWeaponCodex = artifacts.require("theForest_weapon_codex");
const DummyTheForestJewelryCodex = artifacts.require("theForest_jewelry_codex");

use(solidity);

const	RARITY_ADDRESS = '0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb'
let		RARITY;

describe('Tests With Dummy', () => {
	let		rarityExtendedEquipements;
	let		dummy;
	let		dummyCodex;
    let		user;
	let		adventurerPool = [];

    before(async () => {
        await deployments.fixture();
        [user, anotherUser] = await ethers.getSigners();
		RARITY = new ethers.Contract(RARITY_ADDRESS, [
			'function next_summoner() public view returns (uint)',
			'function summon(uint _class) external',
			'function setApprovalForAll(address operator, bool _approved) external',
		], user);
		rarityExtendedEquipements = await RarityExtendedEquipements.new()
		dummy = await Dummy.new()
		dummyCodex = await DummyArmorCodex.new()
    });

	
	it('should be possible to get the name of the contract', async function() {
		const	name = await rarityExtendedEquipements.name();
		await	expect(name).to.be.equal('Rarity Extended Equipement');
	})

	it('should be possible to summon 1 adventurer', async function() {
		const	nextAdventurer = Number(await RARITY.next_summoner());
		await	(await RARITY.summon(1)).wait();
		adventurerPool.push(nextAdventurer);
	})
	it('should be possible to summon another adventurer', async function() {
		RARITY2 = new ethers.Contract(RARITY_ADDRESS, [
			'function next_summoner() public view returns (uint)',
			'function summon(uint _class) external',
		], anotherUser);
		const	nextAdventurer = Number(await RARITY2.next_summoner());
		await	(await RARITY2.summon(2)).wait();
		adventurerPool.push(nextAdventurer);
	})

	it('should be possible to register one codex', async function() {
		await expect(rarityExtendedEquipements.registerCodex(
			dummy.address,
			ethers.constants.AddressZero,
			dummyCodex.address,
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible for this adventurer to craft equipement 0', async function() {
		await expect(dummy.craft(adventurerPool[0], 2, 2, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft shield 1', async function() {
		await expect(dummy.craft(adventurerPool[0], 2, 4, {from: user.address})).not.to.be.reverted;
	})
	it('the adventurer should be the owner of the shield ', async function() {
		const armorOwner = await dummy.ownerOf(1);
		await expect(armorOwner).to.be.equal(user.address);
	})

	it('the adventurer should be able to approve the spending of the equipement 0 by the contract', async function() {
		await expect(dummy.approve(
			rarityExtendedEquipements.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to approve the spending of the equipement 1 by the contract', async function() {
		await expect(dummy.approve(
			rarityExtendedEquipements.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to set_equipement (set armor)', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,address,address,address,uint256,uint8)'](
			adventurerPool[0],
			user.address,
			dummy.address,
			dummy.address,
			0,
			2,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_equipement (set shield)', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,address,address,address,uint256,uint8)'](
			adventurerPool[0],
			user.address,
			dummy.address,
			dummy.address,
			1,
			9,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipements.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(2);
		await expect(Number(adventurerArmor[2])).to.be.equal(1);
		await expect(Number(adventurerArmor[3])).to.be.equal(5);
		await expect(Number(adventurerArmor[4])).to.be.equal(1);
		await expect(Number(adventurerArmor[5])).to.be.equal(4);
		await expect(Number(adventurerArmor[6])).to.be.equal(0);
		await expect(Number(adventurerArmor[7])).to.be.equal(5);
		await expect(adventurerArmor[8]).to.be.equal("Dead hero cape");
		await expect(adventurerArmor[9]).to.be.equal("We honor his former owner, a hero with no name.");
	})
	it('should be possible to get the details ot the adventurer shield', async function() {
		const	adventurerArmor = await rarityExtendedEquipements.get_shield(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(4);
		await expect(Number(adventurerArmor[2])).to.be.equal(4);
		await expect(Number(adventurerArmor[3])).to.be.equal(30);
		await expect(Number(adventurerArmor[4])).to.be.equal(5);
		await expect(Number(adventurerArmor[5])).to.be.equal(3);
		await expect(Number(adventurerArmor[6])).to.be.equal(-4);
		await expect(Number(adventurerArmor[7])).to.be.equal(25);
		await expect(adventurerArmor[8]).to.be.equal("It's a random shield");
		await expect(adventurerArmor[9]).to.be.equal("Yep, random");
	})

	it('the adventurer should be able to unset_equipement (armor)', async function() {
		await expect(rarityExtendedEquipements.unset_equipement(adventurerPool[0], 2, {from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to unset_equipement (shield)', async function() {
		await expect(rarityExtendedEquipements.unset_equipement(adventurerPool[0], 9, {from: user.address})
		).not.to.be.reverted;
	})


	it('the adventurer should be able to approve the spending of the equipement by the contract', async function() {
		await expect(dummy.approve(
			rarityExtendedEquipements.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to approve the spending of the equipement by the contract', async function() {
		await expect(dummy.approve(
			rarityExtendedEquipements.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should not be able to set_equipement with the shield as armor', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,address,address,address,uint256,uint8)'](
			adventurerPool[0],
			user.address,
			dummy.address,
			dummy.address,
			1,
			2,
			{from: user.address})
		).to.be.revertedWith("shield");
	})
	it('the adventurer should not be able to set_equipement with the armor as shield', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,address,address,address,uint256,uint8)'](
			adventurerPool[0],
			user.address,
			dummy.address,
			dummy.address,
			0,
			9,
			{from: user.address})
		).to.be.revertedWith("!shield");
	})
});

describe('Tests With TheForest', () => {
	let		rarityExtendedEquipements;
    let		user;
	let		adventurerPool = [];
	let		equipementManager;
	let		dummyTheForest;
	let		dummyTheForestItemsProxy;
	let		dummyTheForestGoodsCodex;
	let		dummyTheForestArmorCodex;
	let		dummyTheForestWeaponCodex;
	let		dummyTheForestJewelryCodex;


    before(async () => {
        await deployments.fixture();
        [user, anotherUser] = await ethers.getSigners();
		RARITY = new ethers.Contract(RARITY_ADDRESS, [
			'function next_summoner() public view returns (uint)',
			'function summon(uint _class) external',
			'function setApprovalForAll(address operator, bool _approved) external',
		], user);
		rarityExtendedEquipements = await RarityExtendedEquipements.new()
		dummyTheForest = await DummyTheForest.new(
			"0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb",
			"0xb37d3d79ea86B0334d9322c695339D577A3D57be",
			"0x9e894cd5dCC5Bad1eD3663077871d9D010f654b5",
			"0x640bdeff13ae5527424acd868F65357270b05eB8",
		);

		dummyTheForestItemsProxy = await DummyTheForestItemsProxy.new(dummyTheForest.address);
		dummyTheForestGoodsCodex = await DummyTheForestGoodsCodex.new();
		dummyTheForestArmorCodex = await DummyTheForestArmorCodex.new();
		dummyTheForestWeaponCodex = await DummyTheForestWeaponCodex.new();
		dummyTheForestJewelryCodex = await DummyTheForestJewelryCodex.new();
		equipementManager = await rarityExtendedEquipements.manager();
    });

	
	it('should be possible to get the name of the contract', async function() {
		const	name = await rarityExtendedEquipements.name();
		await	expect(name).to.be.equal('Rarity Extended Equipement');
	})

	it('should be possible to summon 1 adventurer', async function() {
		const	nextAdventurer = Number(await RARITY.next_summoner());
		await	(await RARITY.summon(1)).wait();
		adventurerPool.push(nextAdventurer);
	})

	it('should be possible to register one codex', async function() {
		await expect(rarityExtendedEquipements.registerCodex(
			dummyTheForestItemsProxy.address,
			dummyTheForestGoodsCodex.address,
			dummyTheForestArmorCodex.address,
			dummyTheForestWeaponCodex.address,
			dummyTheForestJewelryCodex.address,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible for this adventurer to craft equipement 0', async function() {
		await expect(dummyTheForest.discover(adventurerPool[0], {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft shield 1', async function() {
		await expect(dummyTheForest.discoverShield(adventurerPool[0], {from: user.address})).not.to.be.reverted;
	})
	it('the adventurer should be the owner of the shield ', async function() {
		const armorOwner = await dummyTheForest.ownerOf(1);
		await expect(Number(armorOwner)).to.be.equal(adventurerPool[0]);
	})

	it('the adventurer should be able to approve the spending of the equipement 0 by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			0,
			{from: user.address})
		).not.to.be.reverted;
		await (await RARITY.setApprovalForAll(rarityExtendedEquipements.address, true)).wait(); //specific for theForest
	})
	it('the adventurer should be able to approve the spending of the equipement 1 by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to set_equipement (set armor)', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,uint256,address,address,uint256,uint8)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			2,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_equipement (set shield)', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,uint256,address,address,uint256,uint8)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			9,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipements.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(3);
		await expect(Number(adventurerArmor[2])).to.be.equal(2);
		await expect(Number(adventurerArmor[3])).to.be.equal(30);
		await expect(Number(adventurerArmor[4])).to.be.equal(5);
		await expect(Number(adventurerArmor[5])).to.be.equal(3);
		await expect(Number(adventurerArmor[6])).to.be.equal(-4);
		await expect(Number(adventurerArmor[7])).to.be.equal(25);
		await expect(adventurerArmor[8]).to.be.equal("Slain warrior armor");
		await expect(adventurerArmor[9]).to.be.equal("I hope you find it useful.");
	})
	it('should be possible to get the details ot the adventurer shield', async function() {
		const	adventurerArmor = await rarityExtendedEquipements.get_shield(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(4);
		await expect(Number(adventurerArmor[2])).to.be.equal(4);
		await expect(Number(adventurerArmor[3])).to.be.equal(30);
		await expect(Number(adventurerArmor[4])).to.be.equal(5);
		await expect(Number(adventurerArmor[5])).to.be.equal(3);
		await expect(Number(adventurerArmor[6])).to.be.equal(-4);
		await expect(Number(adventurerArmor[7])).to.be.equal(25);
		await expect(adventurerArmor[8]).to.be.equal("It's a random shield");
		await expect(adventurerArmor[9]).to.be.equal("Yep, random");
	})

	it('the adventurer should be able to unset_equipement (armor)', async function() {
		await expect(rarityExtendedEquipements.unset_equipement(adventurerPool[0], 2, {from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to unset_equipement (shield)', async function() {
		await expect(rarityExtendedEquipements.unset_equipement(adventurerPool[0], 9, {from: user.address})
		).not.to.be.reverted;
	})


	it('the adventurer should be able to approve the spending of the equipement 0 by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to approve the spending of the equipement 1 by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should not be able to set_equipement with the shield as armor', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,uint256,address,address,uint256,uint8)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			2,
			{from: user.address})
		).to.be.revertedWith("shield");
	})
	it('the adventurer should not be able to set_equipement with the armor as shield', async function() {
		await expect(rarityExtendedEquipements.methods['set_equipement(uint256,uint256,address,address,uint256,uint8)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			9,
			{from: user.address})
		).to.be.revertedWith("!shield");
	})
});
