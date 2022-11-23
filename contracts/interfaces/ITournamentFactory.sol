// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface ITournamentFactory is IERC721 {
    enum Status {
        NOT_ENLISTED,
        PARTICIPANT,
        WINNER,
        PRIZE_REDEEMED
    }

    enum SkillType {
        TRACE,
        HOPLOMACHUS,
        RETIARIUS
    }

    struct WarriorData {
        uint256 xp;
        SkillType skill;
    }

    function newTournament(
        uint256 price,
        uint256 duration,
        uint256 lifePoints
    ) external;

    function deathHook(uint256 warriorID, bool winner) external;

    function getWarriorData(uint256 id) external view returns (WarriorData memory);

    function enlist(address _tournament, uint256 warriorID) external payable;
}
