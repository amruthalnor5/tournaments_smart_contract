//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Tournaments is Ownable {

    struct User {
        address user;
        uint256 score;
    }
    
    struct Tournament {
        uint256 id;
        uint256 lobbySize;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint => User[]) public tourParticipants;
    
    Tournament[] public tournaments;

    uint public constant tourDuration = 600; // 10 minutes
    
    event TournamentAdded(uint256 id, uint256 lobbySize);
    event UserJoinedTournament(uint256 tournamentId, address user);
    event TournamentStarted(uint256 tournamentId);

    constructor() {

    }

    modifier joinModi(uint256 _tournamentId) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(tournament.startTime == 0, "Tournament is already started!");
        require(tourParticipants[_tournamentId].length < tournament.lobbySize, "Tournament is full");
        User[] memory users = tourParticipants[_tournamentId];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].user == msg.sender) {
                revert("You are already joined!");
            }
        }
        _;
    }

    modifier addScoreModi(uint256 _tournamentId) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(tournament.startTime != 0, "Tournament is not started yet!");
        require(block.timestamp < tournament.endTime, "Tournament is already ended!");
        _;
    }

    function addTournament(uint256 _lobbySize) public onlyOwner {
        uint256 id = tournaments.length + 1;
        tournaments.push(Tournament(id, _lobbySize, 0, 0));
        emit TournamentAdded(id, _lobbySize);
    }

    function getSingleTournament(uint256 _tournamentId) public view returns(Tournament memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        return tournament;
    }
    
    function getActiveTournaments() public view returns (Tournament[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                count++;
            }
        }
        Tournament[] memory activeTournaments= new Tournament[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                activeTournaments[index] = tournaments[i];
                index++;
            }
        }
        return activeTournaments;
    }

    function getOngoingTournaments() public view returns (Tournament[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (block.timestamp >= tournaments[i].startTime && tournaments[i].startTime != 0 && block.timestamp <= tournaments[i].endTime && tournaments[i].endTime != 0) {
                count++;
            }
        }
        Tournament[] memory onGoingTournaments= new Tournament[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (block.timestamp >= tournaments[i].startTime && tournaments[i].startTime != 0 && block.timestamp <= tournaments[i].endTime && tournaments[i].endTime != 0) {
                onGoingTournaments[index] = tournaments[i];
                index++;
            }
        }
        return onGoingTournaments;
    }
    
    function joinTournament(uint256 _tournamentId) public joinModi(_tournamentId) returns(bool) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        tourParticipants[_tournamentId].push(User(msg.sender, 0));

        emit UserJoinedTournament(_tournamentId, msg.sender);
        if (tourParticipants[_tournamentId].length == tournament.lobbySize) {
            tournament.startTime = block.timestamp;
            tournament.endTime = block.timestamp + tourDuration;
            tournaments[_tournamentId - 1] = tournament;
            emit TournamentStarted(_tournamentId);
        }
        return true;
    }

    function getTourParticipants(uint _tournamentId) public view returns(User[] memory) {
        User[] memory participants = tourParticipants[_tournamentId];
        return participants;
    }

    function addScore(uint256 _tournamentId, address _user, uint _score) public addScoreModi(_tournamentId) onlyOwner returns(bool _done) {
        User[] memory user = tourParticipants[_tournamentId];
   
        for (uint256 i = 0; i < user.length; i++) {
            if (user[i].user == _user) {
                tourParticipants[_tournamentId][i].score = user[i].score + _score;
                return(true);
            }
        }
    }
    
    function getLeaderboard(uint256 _tournamentId) public view returns(User[] memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(block.timestamp > tournament.endTime && tournament.endTime != 0, "Tournament has not ended yet");
        User[] memory sortedParticipants = sortParticipants(tourParticipants[_tournamentId]);
        return sortedParticipants;
    }
    
    function sortParticipants(User[] memory _participants) private pure returns (User[] memory) {
        for (uint256 i = 0; i < _participants.length - 1; i++) {
            for (uint256 j = i + 1; j < _participants.length; j++) {
                if (_participants[i].score < _participants[j].score) {
                    uint256 tempScore = _participants[i].score;
                    address tempAddress = _participants[i].user;
                    _participants[i].score = _participants[j].score;
                    _participants[i].user = _participants[j].user;
                    _participants[i].score = tempScore;
                    _participants[j].user = tempAddress;
                }
            }
        }
        return _participants;
    }
}
