import React, { useState } from 'react';

import Button from "@material-ui/core/Button";
import Grid from "@material-ui/core/Grid";
import Typography from "@material-ui/core/Typography";


import { ABI, operatorAddress } from './index'
import "./fonts.css"
import { useGenericContract } from '../../../../common/hooks'
import { useWeb3Context, useAccountEffect } from 'web3-react/hooks'


const reportStatusResources=['Lively', 'Lost', 'Found', 'Removed', 'Rewarded'];


export default function WhatOptionYouPreferView ({ ein }) {
  
	const Box = require('3box');
	
	const context = useWeb3Context()
	
	const resolverContract = useGenericContract(operatorAddress, ABI)

	//3box instanceof
	const [userBox, setUserBox] = useState();
	
	//logged user data
	const [totalVotes, setTotalVotes] = useState("000");
	const [totalRewards, setTotalRewards] = useState("000000");

	//current campaign data
	const [activeCampaigns, setActiveCampaigns] = useState([]);
	const [currentCampaign, setCurrentCampaign] = useState(0);
	const [option1Text, setOption1Text] = useState("Fetching data...");
	const [option2Text, setOption2Text] = useState("Fetching data...");

	//total campaigns
	const [totalCampaigns, setTotalCampaigns] = useState(3);

	useAccountEffect(() => {
		refreshUserStats();
		getActiveCampaigns();
		
		open3Box();
	})
  
  function getActiveCampaigns(){
	  debugger;
	  //var a = resolverContract.methods.activeCampaigns();
	  //resolverContract.methods.activeCampaigns.call()
      //    .then(campaigns => {
	//		  setActiveCampaigns(campaigns);
			  setCurrentCampaign(0);
			  refreshCurrentCampaign()
	//	  });
  }
  
  
	function refreshUserStats() {
		resolverContract.methods.getOwner(ein).call()
          .then(owner => {
				setTotalVotes(owner.numPlayedGames)
				setTotalRewards(owner.earnedHydro)
		});
	}
	
	//To be called when currentCampaign changes.
	function refreshCurrentCampaign() {
		debugger;
		resolverContract.methods.campaigns(currentCampaign).call()
			.then(camp =>{
				setOption1Text(camp.option1Description)
				setOption2Text(camp.option2Description)
			});
		
		//setOption1Text( "Discover the Lock Ness Monster")
		//setOption2Text( "Discover the Sasquatch")
	}
	
  
	function handleClickNextCampaign() {
		debugger;
		if((currentCampaign+1) == totalCampaigns){
			setCurrentCampaign(0);
		}else{
			setCurrentCampaign(currentCampaign+1)
		}
		refreshCurrentCampaign();
	}
	
	function handleClickPrevCampaign() {
		debugger;
		if(currentCampaign == 0){
			setCurrentCampaign(totalCampaigns-1);
		}else{
			setCurrentCampaign(currentCampaign-1)
		}
		refreshCurrentCampaign();
	}
	
		
	function getLastCreated(){
		debugger;
		
	}
 
	
	
	async function open3Box(){
		debugger;
	
		const box = await Box.openBox(context.account,context.library.currentProvider)
		await box.onSyncDone(syncComplete);
		setUserBox(box);
	
	}
	
	function syncComplete(){
		console.log('Sync Complete')
	}

   return (
    <div>
      <div align="center">
        <Typography
          variant="h2"
          color="textSecondary"
          class="scorebar"
          gutterBottom
        >
          Played {totalVotes} Times - {totalRewards} HYDRO earned
        </Typography>
      </div>
      <div align="center">
        <Typography
          variant="h5"
          color="textPrimary"
          class="example"
          gutterBottom
        >
          What option do you prefer...?
        </Typography>
      </div>
      <Grid
        container
        spacing="3"
        direction="column"
        justify="center"
        alignItems="center"
      >
        <Grid item>
          <Button class="eightbit-btn eightbit-btn">
            <Typography class="vt323">{option1Text}</Typography>
          </Button>
        </Grid>
        <Grid>
          <Typography
            class="example"
            variant="h5"
            color="textPrimary"
            gutterBottom
          >
            Or
          </Typography>
        </Grid>
        <Grid item>
          <Button class="eightbit-btn eightbit-btn">
            <Typography class="vt323"> {option2Text}</Typography>
          </Button>
        </Grid>
        <p>&nbsp;</p>
      </Grid>
      <div>
        <Grid
          container
          direction="row"
          justify="space-around"
          alignItems="flex-end"
        >
          <Button onClick={handleClickPrevCampaign} class="eightbit-btn eightbit-btn--reset">&lt;</Button>
          <Typography
            class="example"
            variant="h5"
            color="textPrimary"
            gutterBottom
          >
            #{currentCampaign}
          </Typography>
          <Button onClick={handleClickNextCampaign} class="eightbit-btn eightbit-btn--reset">&gt;</Button>
        </Grid>
      </div>
    </div>
  
  );
}







