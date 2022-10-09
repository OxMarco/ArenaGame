// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { ITournament } from "./interfaces/ITournament.sol";
import { IBattleLogicHandler } from "./interfaces/IBattleLogicHandler.sol";

contract Tournament is ITournament {
    address public immutable owner;
    ITournamentFactory public immutable factory;
    IBattleLogicHandler public battleHandler;
    uint256 public immutable priceToJoin;
    uint256 public immutable totalDuration;
    uint256 public startTime;
    uint256 public latestTrigger;
    uint256 public immutable initialLifePoints;
    mapping(uint256 => uint256) public scores;

    struct GameData {
        uint256 xp;
        ITournamentFactory.SkillType skill;
        uint256 lifePoints;
        uint256 attacks;
        bool enlisted;
    }
    mapping(uint256 => GameData) public warriors;
    uint256 public totalPax;

    event TournamentStarted();
    event NewWarriorEnlisted(uint256 indexed warriorID);
    event WarriorHasDied(uint256 indexed warriorID);
    event BattleLogicHandlerWasChanged(address indexed handler);

    error Invalid_WarriorID(uint256 id);
    error Starting_Condition_Unmet();
    error Already_Enlisted();
    error Already_Started();
    error Execution_Throttled();

    constructor(
        uint256 price,
        uint256 duration,
        uint256 lifePoints,
        address battleLogic
    ) {
        battleHandler = IBattleLogicHandler(battleLogic);
        (bool success, bytes memory data) = (msg.sender).call(abi.encodeWithSignature("owner()"));
        assert(success);
        owner = abi.decode(data, (address));

        factory = ITournamentFactory(msg.sender);
        startTime = 0;
        latestTrigger = 0;
        totalPax = 0;
        priceToJoin = price;
        totalDuration = duration;
        initialLifePoints = lifePoints;
    }

    modifier onlyFactory() {
        assert(msg.sender == address(factory));
        _;
    }

    // Governance functions

    function setBattleLogicHandler(address _battleHandler) external {
        assert(msg.sender == owner);

        battleHandler = IBattleLogicHandler(_battleHandler);

        emit BattleLogicHandlerWasChanged(_battleHandler);
    }

    // State getter functions

    function isActive() public view override returns (bool) {
        return (startTime != 0 && totalDuration - startTime < block.timestamp);
    }

    function hasPlayed(uint256 warriorID) external view override returns (bool) {
        return warriors[warriorID].enlisted;
    }

    function totalPrize() external view override returns (uint256) {
        return totalPax * priceToJoin;
    }

    // Public facing functions

    function enlist(uint256 warriorID) external override onlyFactory {
        if (warriors[warriorID].enlisted) revert Already_Enlisted();
        if (startTime != 0) revert Already_Started();

        ITournamentFactory.WarriorData memory data = factory.getWarriorData(warriorID);
        warriors[warriorID] = GameData(data.xp, data.skill, initialLifePoints, 0, true);
        totalPax++;

        emit NewWarriorEnlisted(warriorID);
    }

    function start() external override {
        if (!_start()) revert Starting_Condition_Unmet();

        startTime = block.timestamp;

        emit TournamentStarted();
    }

    function dailyCombat() external override {
        assert(isActive());
        if (latestTrigger + 1 days < block.timestamp) revert Execution_Throttled();

        // TBD
        // - battle logic
        // - premium for execution
    }

    // Internal functions

    function _battle(uint256 attackerID, uint256 defenderID) internal {
        GameData storage attacker = warriors[attackerID];
        GameData storage defender = warriors[defenderID];

        assert(attacker.lifePoints > 0);
        assert(defender.lifePoints > 0);

        if (!attacker.enlisted) revert Invalid_WarriorID(attackerID);
        if (!defender.enlisted) revert Invalid_WarriorID(defenderID);

        (uint256 attackerLifePoints, uint256 defenderLifePoints) = battleHandler.attack(
            attacker.xp,
            attacker.skill,
            defender.xp,
            defender.skill
        );
        if (attackerLifePoints == 0) {
            _die(attackerID);
        } else {
            attacker.lifePoints = attackerLifePoints;
        }

        if (defenderLifePoints == 0) {
            _die(defenderID);
        } else {
            defender.lifePoints = defenderLifePoints;
        }

        // TBD - assign score
    }

    function _die(uint256 warriorID) internal {
        delete warriors[warriorID];

        ITournamentFactory(factory).deathHook(warriorID, _isWinner(warriorID));

        emit WarriorHasDied(warriorID);
    }

    function _start() internal view returns (bool) {
        // TBD
    }

    function _isWinner(uint256) internal returns (bool) {
        // TBD
    }
}
