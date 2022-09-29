// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";

abstract contract BaseTournament {
    ITournamentFactory public immutable factory;
    uint256 public immutable priceToJoin;
    uint256 public immutable totalDuration;
    uint256 public startTime;
    uint256 public immutable initialLifePoints;

    struct GameData {
        uint256 xp;
        ITournamentFactory.SkillType skill;
        uint256 lifePoints;
        uint256 attacks;
        bool enlisted;
    }
    mapping(uint256 => GameData) public warriors;

    event TournamentHasStarted();
    event NewWarriorWasEnlisted(uint256 indexed warriorID);
    event WarriorHasDied(uint256 indexed warriorID);

    error Invalid_Value_Transferred();
    error Invalid_WarriorID(uint256 id);
    error Already_Enlisted();
    error Starting_Condition_Unmet();

    constructor(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) {
        factory = ITournamentFactory(msg.sender);
        priceToJoin = price;
        totalDuration = duration;
        startTime = 0;
        initialLifePoints = lifePoints;
    }

    function isActive() external view returns (bool) {
        return (startTime != 0 && totalDuration - startTime < block.timestamp);
    }

    function enlist(uint256 warriorID) external payable {
        if (msg.value != priceToJoin) revert Invalid_Value_Transferred();
        if (warriors[warriorID].enlisted) revert Already_Enlisted();

        ITournamentFactory.WarriorData memory data = factory.getWarriorData(warriorID);
        warriors[warriorID] = GameData(data.xp, data.skill, initialLifePoints, 0, true);

        emit NewWarriorWasEnlisted(warriorID);
    }

    function start() external {
        if (!_start()) revert Starting_Condition_Unmet();

        startTime = block.timestamp;

        emit TournamentHasStarted();
    }

    function battle(uint256 attackerID, uint256 defenderID) external {
        GameData storage attacker = warriors[attackerID];
        GameData storage defender = warriors[defenderID];

        if (!attacker.enlisted) revert Invalid_WarriorID(attackerID);
        if (!defender.enlisted) revert Invalid_WarriorID(defenderID);

        // assign points and handle deaths
        (uint256 attackerLifePoints, uint256 defenderLifePoints) = _attack(
            attacker.xp,
            attacker.skill,
            defender.xp,
            defender.skill
        );
        if (attackerLifePoints == 0) {
            die(attackerID);
        } else {
            attacker.lifePoints = attackerLifePoints;
        }

        if (defenderLifePoints == 0) {
            die(defenderID);
        } else {
            defender.lifePoints = defenderLifePoints;
        }
    }

    function die(uint256 warriorID) internal {
        delete warriors[warriorID];

        ITournamentFactory(factory).deathHook(warriorID);

        emit WarriorHasDied(warriorID);
    }

    // custom start logic
    function _start() internal virtual returns (bool) {}

    // custom combat logic
    function _attack(
        uint256 attackerXp,
        ITournamentFactory.SkillType attackerSkill,
        uint256 defenderXp,
        ITournamentFactory.SkillType defenderSkill
    ) internal virtual returns (uint256, uint256) {}
}
