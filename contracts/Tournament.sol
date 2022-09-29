// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { BaseTournament } from "./BaseTournament.sol";

contract Tournament is BaseTournament {
    constructor(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) BaseTournament(price, duration, lifePoints) {}

    function _start() internal override returns (bool) {
        // TBD
    }

    function _attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill
    ) internal override returns (uint256, uint256) {
        // TBD
    }
}
