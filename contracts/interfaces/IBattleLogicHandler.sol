// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ITournamentFactory } from "./ITournamentFactory.sol";
interface IBattleLogicHandler {
    function attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 attackerLP,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill,
        uint256 dedenderLP
    ) external returns (uint256, uint256);

    //function computeGladiatorLP(uint256 attackDamage, uint256 attackXp) external;
}
