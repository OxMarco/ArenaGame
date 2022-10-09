// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { IBattleLogicHandler } from "./interfaces/IBattleLogicHandler.sol";

contract BattleLogicHandler is IBattleLogicHandler {
    function attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill
    ) external view returns (uint256, uint256) {
        // TBD
    }
}
