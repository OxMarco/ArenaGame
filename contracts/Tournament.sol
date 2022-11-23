// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ITournamentFactory } from "./interfaces/ITournamentFactory.sol";
import { ITournament } from "./interfaces/ITournament.sol";
import { IBattleLogicHandler } from "./interfaces/IBattleLogicHandler.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Tournament is ITournament {
    address public immutable owner;
    ITournamentFactory public immutable factory;
    IBattleLogicHandler public battleHandler;
    address public GladiatorCollection;
    uint256 public immutable override priceToJoin;
    uint256 public immutable totalDuration;
    uint256 public startTime;
    uint256 public latestTrigger;
    uint256 public immutable initialLifePoints;
    uint256 public lastDayClosed;
    uint256 public day;
    mapping(uint256 => uint256) public override scores;

    struct GameData {
        uint256 xp;
        ITournamentFactory.SkillType skill;
        uint256 lifePoints;
        uint256 attacks;
        bool enlisted;
        uint256 lastAttackDay;
    }

    mapping(uint256 => GameData) public warriors;
    uint256 public override totalPax;

    event TournamentStarted();
    event NewWarriorEnlisted(uint256 indexed warriorID);
    event WarriorHasDied(uint256 indexed warriorID);
    event BattleLogicHandlerWasChanged(address indexed handler);

    error Invalid_WarriorID(uint256 id);
    error Starting_Condition_Unmet();
    error Already_Enlisted();
    error Already_Started();
    error Execution_Throttled();
    error Only_Random_Battle_Allowed();
    error Only_Battle_Allowed();

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
        GladiatorCollection = msg.sender;
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
        warriors[warriorID] = GameData(data.xp, data.skill, initialLifePoints, 0, true, 0);
        totalPax++;

        emit NewWarriorEnlisted(warriorID);
    }

    function start() external override {
        if (!_start()) revert Starting_Condition_Unmet();
        startTime = block.timestamp;
        lastDayClosed = startTime;
        emit TournamentStarted();
    }
    
    function battle(uint256 attackerID, uint256 defenderID) external override {
        assert(isActive());
        assert(IERC721(GladiatorCollection).ownerOf(attackerID) == msg.sender);
        if(checkPeriod() != 1) revert Only_Random_Battle_Allowed();
        _battle(attackerID, defenderID);
    }
    
    function randomBattle(uint256 attackerID, uint256 defenderID) external override {
        assert(isActive());
        if(checkPeriod() != 2) revert Only_Battle_Allowed();
        _battle(attackerID, defenderID);
        // maybe add a onlyRelayer modifier if we want that this randon battle is only executed by a Relayer address
        // - premium for execution
    }
    
    function checkPeriod() public view returns (uint256) {
        uint256 period = (lastDayClosed + 1 days) - 1 hours;
        if (lastDayClosed < block.timestamp && block.timestamp <= period) {
            return 1;
        }
        if (period < block.timestamp && block.timestamp <= (period + 1 hours)) {
            return 2;
        }
        else {
            return 100;
        }
    }

    // Internal functions

    function _battle(uint256 attackerID, uint256 defenderID) internal {
        if (block.timestamp >= lastDayClosed + 1 days) {
            lastDayClosed = block.timestamp;
            day++;
        }
        require(warriors[attackerID].lastAttackDay < day);
        
        GameData storage attacker = warriors[attackerID];
        GameData storage defender = warriors[defenderID];

        assert(attacker.lifePoints > 0);
        assert(defender.lifePoints > 0);

        if (!attacker.enlisted) revert Invalid_WarriorID(attackerID);
        if (!defender.enlisted) revert Invalid_WarriorID(defenderID);

        (uint256 attackerLifePoints, uint256 defenderLifePoints) = battleHandler.attack(
            attacker.xp,
            attacker.skill,
            attacker.lifePoints,
            defender.xp,
            defender.skill,
            defender.lifePoints
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
        
        warriors[attackerID].lastAttackDay = day;
        attacker.xp += 1;
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
