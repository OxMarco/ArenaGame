// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ITournamentFactory } from "./ITournamentFactory.sol";

interface IBattleLogicHandler {
    function attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill
    ) external view returns (uint256, uint256);
}
