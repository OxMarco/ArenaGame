// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { IBattleLogicHandler } from "./interfaces/IBattleLogicHandler.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract BattleLogicHandler is IBattleLogicHandler {

    /* This contract manages the battle logic of a Tournament
       In This version of the BattleLogicHandler the damage made by an attack is calculate using the following factors:
       1) effectiveness of the attacker against the defender. It depends on Gladiators class (TRACE,HOPLOMACHUS,RETIARIUS)
       2) XP difference between attacker and defender
       3) random factor (using ETH price) amplifing/reducing the damage
    */

    AggregatorV3Interface internal priceFeed;

    mapping(ITournamentFactory.SkillType => mapping(ITournamentFactory.SkillType => uint256)) public damages;
    
    constructor() {
        _initializeGladiatorDamages();
        priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
    }

    function _initializeGladiatorDamages() internal {
        damages[ITournamentFactory.SkillType.TRACE][ITournamentFactory.SkillType.HOPLOMACHUS] = 3;
        damages[ITournamentFactory.SkillType.TRACE][ITournamentFactory.SkillType.TRACE] = 1;
        damages[ITournamentFactory.SkillType.TRACE][ITournamentFactory.SkillType.RETIARIUS] = 2;

        damages[ITournamentFactory.SkillType.HOPLOMACHUS][ITournamentFactory.SkillType.RETIARIUS] = 3;
        damages[ITournamentFactory.SkillType.HOPLOMACHUS][ITournamentFactory.SkillType.HOPLOMACHUS] = 1;
        damages[ITournamentFactory.SkillType.HOPLOMACHUS][ITournamentFactory.SkillType.TRACE] = 2;

        damages[ITournamentFactory.SkillType.RETIARIUS][ITournamentFactory.SkillType.TRACE] = 3;
        damages[ITournamentFactory.SkillType.RETIARIUS][ITournamentFactory.SkillType.RETIARIUS] = 1;
        damages[ITournamentFactory.SkillType.RETIARIUS][ITournamentFactory.SkillType.HOPLOMACHUS] = 2;
    }

    function attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 attackerLp,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill,
        uint256 defenderLp
    ) external override view returns (uint256, uint256) {
        uint256 damage = damages[attackerSkill][defenderSkill];
        uint256 XpDifference = attackerXp > defenderXp ? (attackerXp - defenderXp) : 0;
        (uint256 attLP, uint256 defLP) = computeGladiatorLP(attackerLp, defenderLp, damage, XpDifference);
        return(attLP,defLP);
    }

    function computeGladiatorLP(uint256 attLp, uint256 defLp, uint256 attackDamage, uint256 XpDiff) public view returns(uint256, uint256) {
        bool randomFactor = getRandomness();
        //uint256 factor;
        //uint256 randomMultiplier = randomFactor == true ? factor : 0;
        // calculate Life Points
    }
    
    function getRandomness() public view returns (bool) {
        int ethPrice = getLatestPrice();
        // do something to make a "random" true/false using ethereum price value
    }
    
    function getLatestPrice() public view returns (int) {
        (uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}
