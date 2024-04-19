// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable(msg.sender){

    // définition des différents mappings, arrays

    mapping(address => Voter) private Voters;
    Proposal[] private proposalList;

    // Id du proposal gagnant

    uint proposalwinnerid;

    // Statut qui sera consulté et modifié dans le contrat

    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;

    // Voteur entité

    struct Voter{
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Proposal entité

    struct Proposal {
        string description;
        uint voteCount;
    }

    // Différents status possibles

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted, 
        VotingSessionEnded,
        VotesTallied
    }

    // Vérifier si l'adresse est whitelistée

    modifier isVoter(){
        require(Voters[msg.sender].isRegistered == true, "t'es pas enregistre toi");
        _;
    }

    // Tous les events 

    event VoterRegistered(address voteAddress);

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);    

    event ProposalRegistered(uint proposalId);

    event Voted(address voter, uint proposalId);

    // Ajouter à la whitelist

    function addwhitelist(address _address) external onlyOwner{

        // Vérifier si il est pas déjà dans la whiteliste

        require(Voters[_address].isRegistered != true, "Deja whitelisted");

        // Creation Voter

        Voters[msg.sender] = Voter(true, false, 0);
    }

    // Enregistrer la proposition

    function registerProposal(string memory _description) external {

        // Check si il est whitelisté

        require(Voters[msg.sender].isRegistered == true, "Il est pas whitelisted le monsieur la");

        // Check l'état
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted);

        proposalList.push(Proposal(_description, 0));

        // Emission de l'évèvement

        emit ProposalRegistered(proposalList.length - 1);
    }

    // Fonctions de changements d'état

    function startProposals() external onlyOwner{
        require(currentStatus == WorkflowStatus.RegisteringVoters);
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposals() external onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted);
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotes() external onlyOwner{
        require(currentStatus == WorkflowStatus.ProposalsRegistrationEnded);
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotes() external onlyOwner{
        require(currentStatus == WorkflowStatus.VotingSessionStarted);
        currentStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // Permet à tout le monde de récupérer les propositions

    function getProposals() external isVoter view returns(Proposal[] memory) {
        return proposalList;
    }

    // Fonction du vote

    function vote(uint _proposalId) external isVoter {

        // Vérifier l'état

        require(currentStatus == WorkflowStatus.VotingSessionStarted);

        // Vérifier si la proposition existe

        require(bytes(proposalList[_proposalId].description).length > 0, "Cette proposal n'existe visiblement pas");
        
        // Vérifier si le mec a pas déjà voté

        require(Voters[msg.sender].isRegistered != true, "T'as deja vote");

        // Update du voter

        Voters[msg.sender].hasVoted = true;
        Voters[msg.sender].votedProposalId = _proposalId;

        proposalList[_proposalId].voteCount++;

        emit Voted(msg.sender, _proposalId);
    }

    // Calculer qui a gagné

    function whowins() external onlyOwner {

        // Vérification d'état

        require(currentStatus == WorkflowStatus.VotingSessionEnded);
        currentStatus = WorkflowStatus.VotesTallied;

        // initialisation de variables

        uint votecount = 0;
        uint winnerid;

        // boucle sur la longueur de la liste des proposals

        for (uint i = 0; i < proposalList.length; i++) {

            // si la proposition a plus de votes que la précédente alors changer la variable

            if (proposalList[i].voteCount > votecount){
                votecount = proposalList[i].voteCount;
                winnerid = i;
            }
        }

        // L'ID du gagnant est changé

        proposalwinnerid = winnerid;
    }

    // Permet de récupérer la descriptino du gagnant

    function getwinnerdescription() external isVoter view returns (string memory){

        // marche seulement si les votes ont été comptabilisés

        require(currentStatus == WorkflowStatus.VotesTallied);
        return proposalList[proposalwinnerid].description;
    }
}