pragma solidity ^0.5.0;

import "./SnowflakeResolver.sol";
import "./SnowflakeInterface.sol";
import "./SafeMath.sol";
import "./IdentityRegistryInterface.sol";

contract WhatOptionYouPreferResolver is SnowflakeResolver {
    //Revision history
    //v0.1: inicial
    //https://codesandbox.io/s/material-demo-3f4kl
    //using stringSet for stringSet._stringSet;
    using SafeMath for uint;
    
    //Owner Fields
    struct User{
        //string snowflakeId; //PK
        uint ein; //PK
        //string contactName;
        //string contactData;
        uint[] campaignIds;
        uint totalVotes;
        uint totalRewards;
    }
   //Pet fields
    struct Campaign {
        uint id;
        uint ownerId; //snowflakeId of owner of campaign
        uint totalBudget; //100000 HYDRO
        uint pendingBudget; //3500 HYDRO
        uint tipForParticipation; //20 HYDRO
        
        uint endDate; //no new tips, remaining can be done by owner with a refund method
        Status status;
        //string title;
        //string description;
        //string photoUrl;
        //string option1Title;
        string option1Description;
        //string option2Title;
        string option2Description;
        
    }
    
    enum Status { Active, Finished}
    //DATA SECTION
    
    Campaign[]  public campaigns;//campaigns array
    
    uint[] public activeCampaigns;//active campaigns array
    
    
    uint public totalCampaigns; //counter for campaignId
 
    //one hydro is represented as 1000000000000000000
    uint private signUpFee = uint(1).mul(10**18);

    //users registry by ein
    mapping (uint => User) private users;
    
   
    //endUsers of campaign, and their vote.
    //i.e. "user with ein:43 vote in campaign 1 with vote "0" ==>campaignEndUsersAndVotes[campaignId][UserId] = voteValue
    mapping (uint =>  mapping (uint => string)) private campaignEndUsersAndVotes;
    
    //endUserCampaigns[userId][campaignId] == true
    //endUserCampaigns[userId][0]
     //endUserCampaigns[userId].length=3 => there are three campaings done for userId
    mapping (uint =>  bool[]) private endUserCampaigns;
    
        //modifiers
     //verify if transaction sender is the owner himself
     modifier _onlyOwner(uint ownerId)
     {   
         SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
         IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
         require(ownerId == identityRegistry.getEIN(msg.sender));
         _;
     }
     
      //modifiers
     //verify if transaction sender is the pet owner
     modifier _onlyCampaignOwner(uint campaignId)
     {   
         SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
         IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
         require(campaigns[campaignId].ownerId == identityRegistry.getEIN(msg.sender));
         _;
     }
     
     //verify if transaction sender is not the campaign owner
     modifier _onlyNotPetOwner(uint campaignId)
     {   
         SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
         IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
         require(campaigns[campaignId].ownerId != identityRegistry.getEIN(msg.sender));
         _;
     }
     
     modifier _campaignExists(uint campaignId)
     {
        require(campaignId < campaigns.length,"No campaign exists with that Id");
        _;
     }
   
    //debug method to get max reward
   
     
    constructor (address snowflakeAddress)
        SnowflakeResolver("What Option Do You Prefer v0.1", "Have some fun earn HYDRO tokens!", snowflakeAddress, true, false) public
    {  
        totalCampaigns=0;
        
        
    }
    
       // implement signup function
    function onAddition(uint ein, uint, bytes memory ) 
    public 
    senderIsSnowflake() 
    returns (bool) {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        snowflake.withdrawSnowflakeBalanceFrom(ein, owner(), signUpFee);
       //3. update the mapping owners
            // (string memory contactName, string memory contactData) = abi.decode(extraData, (string, string));
            //users[ein].contactName = contactName;
            //users[ein].contactData = contactData;
       // emit StatusSignUp(ein);
       users[ein].ein = ein;
       //users[ein].contactData = ein;
        return true;
    }
     
    function onRemoval(uint, bytes memory) 
    public 
    senderIsSnowflake() returns (bool) {
        //delete all pets
       // for(uint i=0;i<owners[ein].petIds.length;i++){
        //    string memory petId = owners[ein].petIds[i];
        //    Pet apet = pets[petId];
        //    if(lostReportKeys.contains(petId)){
        //        //remove report
        //        //if Pending, Found or Claimed:
        //        
        //    }
        //}
        //delete all reports
        //return all escrow if any
        //delete owner
         return true;
    }

    function getOwner(uint ownerId)
    public view 
    returns (uint numPlayedGames, uint earnedHydro ){
        return( users[ownerId].totalVotes,
                users[ownerId].totalRewards)  ;  
    }
   
    
   
     //get pet data from petId
    //function getCampaign(uint campaignId) 
    //public view 
    //returns (string memory title) 
    //{
    //   return( 
    //        campaigns[campaignId].title,
    //    );
    //}
 
     
    //The user creates a new campaign
    function createCampaign(uint _ownerId, uint _totalBudget, uint _tipForParticipation, uint _endDate, 
                        //string memory title, 
                        //string memory description,
                        //string memory photoUrl,
                        //string memory option1Title,
                        string memory _option1Description,
                        //string memory option2Title,
                        string memory _option2Description) 
    public 
    _onlyOwner(_ownerId) //0. sender must be ownerId 
    returns (uint )  
    {
        //escrow 
        if(_totalBudget >0){
            SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
          
            require(snowflake.resolverAllowances(_ownerId,address(this)) >= _totalBudget,"Owner's allowance must be equal or greater than totalBudget");
            require(snowflake.deposits(_ownerId) >= _totalBudget,"Owner's funds must be equal or greater than totalBudget");
            
            //2.escrow reward from snowflake to resolver
            snowflake.withdrawSnowflakeBalanceFrom(_ownerId, address(this), _totalBudget.mul(10**18));
        }
        
        //3. update the data
        uint campaignId = totalCampaigns;
     
        Campaign memory newCampaign =Campaign({id:campaignId,
            ownerId:_ownerId,
            totalBudget:_totalBudget,
            pendingBudget:_totalBudget,
            tipForParticipation:_tipForParticipation,
            endDate:_endDate,
            status:Status.Active,
            option1Description:_option1Description,
            option2Description:_option2Description
        });
        campaigns.push(newCampaign);
        activeCampaigns.push(campaignId);
        totalCampaigns++;
        
        //4. register pet ownership
        users[_ownerId].campaignIds.push(campaignId);
  
        //emitEventV2(totalPets-1, lostReports[totalPets-1]);
        
        // Campaign status must be pending
        //require(campaigns[campaignId].status==Status.Pending,"Campaign must be Pending");
        return (campaignId);
    }
    
    
    /**
     * Campaigns can only be updated if not active.
     * 
     */
     
     /*
    function updateCampaign(uint campaignId, uint totalBudget, uint tipForParticipation, uint endDate,
     string memory option1Description, string memory option2Description) 
    public 
    _onlyCampaignOwner(campaignId)
    _campaignExists(campaignId)
    returns (bool success)  
    {
        require(campaigns[campaignId].status == Status.Pending,"Campaign must be pending for update.");
        
        campaigns[campaignId].totalBudget = totalBudget;
        campaigns[campaignId].pendingBudget = totalBudget;
        campaigns[campaignId].tipForParticipation = tipForParticipation;
        campaigns[campaignId].endDate = endDate;
        campaigns[totalCampaigns].option1Description = option1Description;
        campaigns[totalCampaigns].option2Description = option2Description;
        return (true);
    }
    */
    
    /**
     * Owner starts a campaign:
     * - status is set to Active
     * - owner must have HYDRO funds to escrow to contracts
     * - owner tokens get transferred to contract
     */
    function _publishCampaign(uint campaignId)
    private
    _onlyCampaignOwner(campaignId)
    returns (bool success)  
    {
        // Can reward
        
        
        if(campaigns[campaignId].totalBudget >0){
            SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
            IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
            uint ownerId=identityRegistry.getEIN(msg.sender);
            require(snowflake.resolverAllowances(ownerId,address(this)) >= campaigns[campaignId].totalBudget,"Owner's allowance must be equal or greater than totalBudget");
            require(snowflake.deposits(ownerId) >= campaigns[campaignId].totalBudget,"Owner's funds must be equal or greater than totalBudget");
            
            //2.escrow reward from snowflake to resolver
            snowflake.withdrawSnowflakeBalanceFrom(ownerId, address(this), campaigns[campaignId].totalBudget.mul(10**18));
        }
         
        // Campaign status must be pending
        //require(campaigns[campaignId].status==Status.Pending,"Campaign must be Pending");
        
        
        return (true);
    }
    function finishCampaign(uint campaignId)
    public
     _onlyCampaignOwner(campaignId)
     _campaignActive(campaignId){
         
         _internalFinishCampaign(campaignId);
    }
    
    function _internalFinishCampaign(uint campaignId)
    private{
        campaigns[campaignId].status = Status.Finished;
         
        if(campaigns[campaignId].pendingBudget >0){
            SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
            IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
            uint ownerId=identityRegistry.getEIN(msg.sender);
        
            //refund pending budget to campaign ownerId
            transferHydroBalanceTo(ownerId,campaigns[campaignId].pendingBudget.mul(10**18));
         }
        
        campaigns[campaignId].pendingBudget = 0;
        
        //remove from active campaigns array
       for(uint i=0;i<activeCampaigns.length;i++){
            if(activeCampaigns[i] == campaignId){
                activeCampaigns[i] = activeCampaigns[activeCampaigns.length-1];
                activeCampaigns.length--;
                break;
            }
        }
    }
   
   //JOIN campaigns
   
    modifier _onlyNotJoined(uint endUserId, uint campaignId)
     {
         //bytes(lostReports[petId].sceneDesc).length==0
        require(bytes(campaignEndUsersAndVotes[campaignId][endUserId]).length==0,"No campaign exists with that Id");
        _;
     }
     
    modifier _campaignActive(uint campaignId)
     {
         //bytes(lostReports[petId].sceneDesc).length==0
        require(campaigns[campaignId].status== Status.Active,"Campaign is not active");
        _;
     }
      modifier _canPayFromBudget(uint campaignId)
     {
         //bytes(lostReports[petId].sceneDesc).length==0
        require(campaigns[campaignId].pendingBudget >= campaigns[campaignId].tipForParticipation,"Not enought Pending budget!");
        _;
     }  

    function campaignMustBeFinished(uint campaignId)
    private view
    returns (bool){
         return (campaigns[campaignId].endDate >= now 
            || campaigns[campaignId].pendingBudget < campaigns[campaignId].tipForParticipation);
     }

   function voteCampaign(uint endUserId, uint campaignId, string memory vote)
   public
   _campaignExists(campaignId)
   _campaignActive(campaignId)
   _canPayFromBudget(campaignId)
   _onlyNotJoined(endUserId, campaignId)
   returns (bool) {
        
        //add user to list for preventing more votes
        campaignEndUsersAndVotes[campaignId][endUserId] = vote;
        
        if(campaigns[campaignId].tipForParticipation > 0){
            //Tip User
            //make the transfer
            transferHydroBalanceTo(endUserId,campaigns[campaignId].tipForParticipation.mul(10**18));
            campaigns[campaignId].pendingBudget = campaigns[campaignId].pendingBudget-campaigns[campaignId].tipForParticipation;
            
            //update earnedHydro
            users[endUserId].totalRewards = users[endUserId].totalRewards+campaigns[campaignId].tipForParticipation;
            //emitEventV2(petId, lostReports[petId]);
        }
   
        //update participation counters
        users[endUserId].totalVotes++;
        
        //Verify if campaign must be finished
        if(campaignMustBeFinished(campaignId)){
            _internalFinishCampaign(campaignId);
        }
        return(true);
   }
  
}