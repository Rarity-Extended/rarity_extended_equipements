require("dotenv").config();
const { expect, use } = require('chai');
const { solidity } = require('ethereum-waffle');
const { deployments, ethers } = require('hardhat');
const RarityExtendedEquipement = artifacts.require("rarity_extended_equipement");
const DummyArmor = artifacts.require("dummy_armor");
const DummyArmorCodex = artifacts.require("dummy_codex_items_armor");

const DummyRC = artifacts.require("rarity_crafting");
const DummyRCGoodsCodex = artifacts.require("rarity_crafting_codex_good");
const DummyRCArmorCodex = artifacts.require("rarity_crafting_codex_armor");
const DummyRCWeaponCodex = artifacts.require("rarity_crafting_codex_weapon");

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
	let		rarityExtendedEquipement;
	let		dummyArmor;
	let		dummyArmorCodex;
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
		rarityExtendedEquipement = await RarityExtendedEquipement.new()
		dummyArmor = await DummyArmor.new()
		dummyArmorCodex = await DummyArmorCodex.new()
    });

	
	it('should be possible to get the name of the contract', async function() {
		const	name = await rarityExtendedEquipement.name();
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
		await expect(rarityExtendedEquipement.registerCodex(
			dummyArmor.address,
			ethers.constants.AddressZero,
			dummyArmorCodex.address,
			ethers.constants.AddressZero,
			ethers.constants.AddressZero,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible for this adventurer to craft armor 0', async function() {
		await expect(dummyArmor.craft(adventurerPool[0], 2, 2, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft armor 1', async function() {
		await expect(dummyArmor.craft(adventurerPool[0], 2, 1, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft armor 2', async function() {
		await expect(dummyArmor.craft(adventurerPool[0], 2, 3, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for the other adventurer to craft armor 3', async function() {
		await expect(dummyArmor.craft(adventurerPool[1], 2, 3, {from: anotherUser.address})).not.to.be.reverted;
	})

	it('the adventurer should be the owner of the armor ', async function() {
		const armorOwner = await dummyArmor.ownerOf(0);
		await expect(armorOwner).to.be.equal(user.address);
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyArmor.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to set_armor ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to set_armor (revert !already) ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: user.address})
		).to.be.revertedWith('!already');
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
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
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).to.be.revertedWith('!noArmor');
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyArmor.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_armor with the same armor', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
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
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyArmor.approve(
			rarityExtendedEquipement.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_armor with another armor', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(1);
		await expect(Number(adventurerArmor[2])).to.be.equal(1);
		await expect(Number(adventurerArmor[3])).to.be.equal(10);
		await expect(Number(adventurerArmor[4])).to.be.equal(1);
		await expect(Number(adventurerArmor[5])).to.be.equal(8);
		await expect(Number(adventurerArmor[6])).to.be.equal(0);
		await expect(Number(adventurerArmor[7])).to.be.equal(20);
		await expect(adventurerArmor[8]).to.be.equal("Haunted cloak");
		await expect(adventurerArmor[9]).to.be.equal("It has a life of its own, it protects those who use it.");
	})
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})


	//Stuff with another player
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyArmor.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyArmor.address,
			dummyArmor.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyArmor.address,
			dummyArmor.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
});

describe('Tests With Crafting', () => {
	let		rarityExtendedEquipement;
	let		dummyRC;
	let		dummyRCGoodsCodexAddr = '0x0C5C1CC0A7AE65FE372fbb08FF16578De4b980f3';
	let		dummyRCArmorCodexAddr = '0xf5114A952Aca3e9055a52a87938efefc8BB7878C';
	let		dummyRCWeaponCodexAddr = '0xeE1a2EA55945223404d73C0BbE57f540BBAAD0D8';
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
		rarityExtendedEquipement = await RarityExtendedEquipement.new()
		dummyRC = await DummyRC.new();

    });

	
	it('should be possible to get the name of the contract', async function() {
		const	name = await rarityExtendedEquipement.name();
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
		await expect(rarityExtendedEquipement.registerCodex(
			dummyRC.address,
			dummyRCGoodsCodexAddr,
			dummyRCArmorCodexAddr,
			dummyRCWeaponCodexAddr,
			ethers.constants.AddressZero,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible for this adventurer to craft armor 0', async function() {
		await expect(dummyRC.craft(adventurerPool[0], 2, 11, 0, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft armor 1', async function() {
		await expect(dummyRC.craft(adventurerPool[0], 2, 1, 0, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to craft armor 2', async function() {
		await expect(dummyRC.craft(adventurerPool[0], 2, 3, 0, {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for the other adventurer to craft armor 3', async function() {
		await expect(dummyRC.craft(adventurerPool[1], 2, 3, 0, {from: anotherUser.address})).not.to.be.reverted;
	})
	it('the adventurer should be the owner of the armor ', async function() {
		const armorOwner = await dummyRC.ownerOf(0);
		await expect(armorOwner).to.be.equal(user.address);
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyRC.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to set_armor ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to set_armor (revert !already) ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: user.address})
		).to.be.revertedWith('!already');
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(11);
		await expect(Number(adventurerArmor[2])).to.be.equal(3);
		await expect(Number(adventurerArmor[3])).to.be.equal(50);
		await expect(Number(adventurerArmor[4])).to.be.equal(7);
		await expect(Number(adventurerArmor[5])).to.be.equal(0);
		await expect(Number(adventurerArmor[6])).to.be.equal(-7);
		await expect(Number(adventurerArmor[7])).to.be.equal(40);
		await expect(adventurerArmor[8]).to.be.equal("Half-plate");
		await expect(adventurerArmor[9]).to.be.equal("The suit includes gauntlets.");
	})
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).to.be.revertedWith('!noArmor');
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyRC.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_armor with the same armor', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(11);
		await expect(Number(adventurerArmor[2])).to.be.equal(3);
		await expect(Number(adventurerArmor[3])).to.be.equal(50);
		await expect(Number(adventurerArmor[4])).to.be.equal(7);
		await expect(Number(adventurerArmor[5])).to.be.equal(0);
		await expect(Number(adventurerArmor[6])).to.be.equal(-7);
		await expect(Number(adventurerArmor[7])).to.be.equal(40);
		await expect(adventurerArmor[8]).to.be.equal("Half-plate");
		await expect(adventurerArmor[9]).to.be.equal("The suit includes gauntlets.");
	})
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyRC.approve(
			rarityExtendedEquipement.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_armor with another armor', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
		await expect(Number(adventurerArmor[0])).to.be.equal(1);
		await expect(Number(adventurerArmor[2])).to.be.equal(1);
		await expect(Number(adventurerArmor[3])).to.be.equal(10);
		await expect(Number(adventurerArmor[4])).to.be.equal(1);
		await expect(Number(adventurerArmor[5])).to.be.equal(8);
		await expect(Number(adventurerArmor[6])).to.be.equal(0);
		await expect(Number(adventurerArmor[7])).to.be.equal(5);
		await expect(adventurerArmor[8]).to.be.equal("Padded");
		await expect(adventurerArmor[9]).to.be.equal("");
	})
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})


	//Stuff with another player
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyRC.approve(
			rarityExtendedEquipement.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyRC.address,
			dummyRC.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,address,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyRC.address,
			dummyRC.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
});

describe('Tests With TheForest', () => {
	let		rarityExtendedEquipement;
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
		rarityExtendedEquipement = await RarityExtendedEquipement.new()
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
		equipementManager = await rarityExtendedEquipement.manager();
    });

	
	it('should be possible to get the name of the contract', async function() {
		const	name = await rarityExtendedEquipement.name();
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
		await expect(rarityExtendedEquipement.registerCodex(
			dummyTheForestItemsProxy.address,
			dummyTheForestGoodsCodex.address,
			dummyTheForestArmorCodex.address,
			dummyTheForestWeaponCodex.address,
			dummyTheForestJewelryCodex.address,
			{from: user.address})
		).not.to.be.reverted;
	})

	it('should be possible for this adventurer to discover armor 0', async function() {
		await expect(dummyTheForest.discover(adventurerPool[0], {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for this adventurer to discover armor 1', async function() {
		await expect(dummyTheForest.discover(adventurerPool[0], {from: user.address})).not.to.be.reverted;
	})
	it('should be possible for the other adventurer to discover armor 2', async function() {
		await expect(dummyTheForest.discover(adventurerPool[1], {from: anotherUser.address})).not.to.be.reverted;
	})
	it('the adventurer should be the owner of the armor', async function() {
		const armorOwner = await dummyTheForest.ownerOf(0);
		await expect(Number(armorOwner)).to.be.equal(adventurerPool[0]);
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			0,
			{from: user.address})
		).not.to.be.reverted;
		await (await RARITY.setApprovalForAll(rarityExtendedEquipement.address, true)).wait(); //specific for theForest
	})

	it('the adventurer should be able to set_armor ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to set_armor (revert !already) ', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: user.address})
		).to.be.revertedWith('!already');
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
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
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should not be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).to.be.revertedWith('!noArmor');
	})

	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('the adventurer should be able to set_armor with the same armor', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			adventurerPool[0],
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should be possible to get the details ot the adventurer armor', async function() {
		const	adventurerArmor = await rarityExtendedEquipement.get_armor(adventurerPool[0])
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
	it('the adventurer should be able to unset_armor', async function() {
		await expect(rarityExtendedEquipement.unset_armor(adventurerPool[0], {from: user.address})
		).not.to.be.reverted;
	})


	//Stuff with another player
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the armor for my adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('the adventurer should be able to approve the spending of the armor by the contract', async function() {
		await expect(dummyTheForest.approve(
			adventurerPool[0],
			equipementManager,
			1,
			{from: user.address})
		).not.to.be.reverted;
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if another player try to set the my armor for another adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			0,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			user.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if set_armor if called by another player', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[0],
			anotherUser.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!owner');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			user.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
	it('should revert if anotherPlayer want to use the approved equipement from a non owner adventurer', async function() {
		await expect(rarityExtendedEquipement.methods['set_armor(uint256,uint256,address,address,uint256)'](
			adventurerPool[1],
			anotherUser.address,
			dummyTheForestItemsProxy.address,
			dummyTheForest.address,
			1,
			{from: anotherUser.address})
		).to.be.revertedWith('!equipement');
	})
});
