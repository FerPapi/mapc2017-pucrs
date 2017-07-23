task_id(0).

+default::job(_, _, _, _, _, _) : default::step(0).
@job[atomic]
+default::job(Id, Storage, Reward, Start, End, Items)
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<- 
	!strategies::not_free;
	.print("New job ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End);
	.print("Items required: ",Items);
	!!separate_tasks(Id, Storage, Items, End, End - Start, Reward);
	.
+default::job(Id, Storage, Reward, Start, End, Items) <- .print("Ignoring job ",Id).

+default::mission(_, _, _, _, _, _, _, _, _) : default::step(0).
@mission[atomic]
+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items)
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<- 
	!strategies::not_free;
	.print("New mission ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End," or pay ",Fine);
	.print("Items required: ",Items);
	!!separate_tasks(Id, Storage, Items, End, End - Start, Reward);
	.
+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items) <- +mission(Id, Fine, End); .print("Ignoring mission ",Id).
	
@sendfreetrucks[atomic]
+!send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeTrucks) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.
@sendfreeagents[atomic]
+!send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeAgents) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.

+!announce(Task,Deadline,NumberOfAgents,JobId,TaskId,FreeAgents,FreeTrucks)
	: true
<- 
	.concat("cnp_board_",TaskId,CNPBoardName);
	makeArtifact(CNPBoardName, "cnp.ContractNetBoard", [Task, Deadline, NumberOfAgents]);
	if (.substring("assemble",Task)) { !send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId); }
	else { !send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId); }
//	.print("Created cnp ",CNPBoardName," for task ",Task);
	getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
//		.print("Got bids (",.length(Bids),") for task #",Qty," ",ItemId," Bids: ",Bids);
		+bids(Task,Bids,JobId);
	}
	else {
		.print("No bids.");
	}
	remove[artifact_name(CNPBoardName)];
	.

@addCNP[atomic]
+!add_cnp(Id) <- +cnp(Id).
+!separate_tasks(Id, Storage, Items, End, Duration, Reward)
	: not cnp(_) & new::max_bid_time(Deadline) & initiator::free_trucks(FreeTrucks) & .length(FreeTrucks,NumberOfTrucks) & initiator::free_agents(FreeAgents) & .length(FreeAgents,NumberOfAgents) 
<-
	!add_cnp(Id);
	?default::decomposeRequirements(Items,[],Bases);
	+bases([]);
	for ( .member(Item,Bases) ) {
		?bases(L);
		.concat(L,Item,New);
		-+bases(New);
	}
	?bases(B);
	-bases(B);
	if (.substring("tool",B)) {
		?default::separateItemTool(B,ListTools,ListItems); 
		?default::removeDuplicateTool(ListTools,ListToolsNew);
	}
	else { ListToolsNew = []; ListItems = B; }
	.length(Items,NumberOfAssemble);
	!evaluate_job(ListToolsNew, ListItems, Duration, Storage, NumberOfAssemble, Id, Reward, BadJob);
	if (BadJob == "false") {
		+job(Id, Storage, End, Items);
		+number_of_tasks(.length(ListItems)+.length(ListToolsNew)+1,Id);
		?task_id(TaskIdA);
	//	.print("Creating cnp for assemble task ",Storage," free trucks[",NumberOfTrucks,"]: ",FreeTrucks);
		!!announce(assemble(Storage),Deadline,NumberOfTrucks,Id,TaskIdA,FreeAgents,FreeTrucks);
		-+task_id(TaskIdA+1);
		for ( .member(item(ItemId,Qty),ListToolsNew) ) {
			?task_id(TaskId);
			-+task_id(TaskId+1);
	//		.print("Creating cnp for tool task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
			!!announce(tool(ItemId),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
		}
		for ( .member(item(ItemId,Qty),ListItems) ) {
			?task_id(TaskId);
			-+task_id(TaskId+1);
	//		.print("Creating cnp for buy task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
			!!announce(item(ItemId,Qty),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
		}
	}
	else { 
		.print("Job ",Id," failed evaluation, ignoring it.");
		-cnp(Id);
		.my_name(Me);
		if ( .member(Me,FreeAgents) ) { 
			!strategies::free; 
		}
	}
	.
+!separate_tasks(Id, Storage, Items, End, Duration, Reward)
<-
	.wait(500);
	!separate_tasks(Id, Storage, Items, End, Duration, Reward);
	.

@eval[atomic]
+!evaluate_job(ListToolsNew, ListItems, Duration, Storage, NumberOfAssemble, Id, Reward, BadJob)
	: new::vehicle_job(Role,Speed) & new::shopList(SList) & new::workshopList(WList) & .length(ListToolsNew,NumberOfBuyTool) & .length(ListItems,NumberOfBuyItem) & default::steps(TotalSteps) & default::step(Step)
<-
	if ( default::check_buy_list(ListItems,ResultB) & ResultB == "true" & default::check_price(ListToolsNew,ListItems,0,ResultP) & .print("Estimated cost ",ResultP * 1.5," reward ",Reward) & ResultP * 1.5 < Reward & actions.farthest(Role,SList,FarthestShop) & actions.route(Role,Speed,FarthestShop,RouteShop) & actions.closest(Role,WList,Storage,ClosestWorkshop) & actions.route(Role,Speed,FarthestShop,ClosestWorkshop,RouteWorkshop) & actions.route(Role,Speed,ClosestWorkshop,Storage,RouteStorage) & Estimate = RouteShop+RouteWorkshop+RouteStorage+NumberOfBuyTool+NumberOfBuyItem+NumberOfAssemble+30+10 & Estimate < Duration & Step + Estimate < TotalSteps ) {
//		+estimate(Id,Step,RouteShop+RouteWorkshop+RouteStorage+NumberOfBuyTool+NumberOfBuyItem+NumberOfAssemble+30+10);
		BadJob = "false";
	}
	else { BadJob = "true"; }
	.
	
@selectBids[atomic]
+bids(_,_,JobId)
	: .count(initiator::bids(_,_,JobId),NumberOfBids) & number_of_tasks(NumberOfTasks,JobId) & NumberOfBids == NumberOfTasks & .my_name(Me)
<-
	-number_of_tasks(NumberOfTasks,JobId);
	for ( bids(assemble(StorageId),Bids,JobId) ) {
		if ( not initiator::impossible_task(JobId) ) {
			-bids(assemble(StorageId),Bids,JobId);
			?default::select_bid_assemble(Bids,bid(99999,99999),bid(Agent,Distance));
			if (Distance \== 99999) {
				?initiator::job(JobId, _, _, Items);
				+awarded_assemble(Agent,Items,StorageId,JobId);
	//			.print("Awarding assemble to ",Agent);
			}
			else { +initiator::impossible_task(JobId); .print("Unable to allocate assemble to deliver at ",StorageId); }
		}
	}
	for ( bids(tool(ItemId),Bids,JobId) ) {
		if ( not initiator::impossible_task(JobId) ) {
			-bids(tool(ItemId),Bids,JobId);
			?default::select_bid_tool(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
			if (Distance \== 99999) {
				getLoad(Agent,Load);
				?default::item(ItemId,Volume,_,_);
		    	addLoad(Agent,Load-Volume);
	//	    	.print("Awarding ",ItemId," to ",Agent," at",Shop);
				if (not awarded(Agent,_,_,_)) {
					+awarded(Agent,Shop,[tool(ItemId)],JobId);
				}
				else {
					?awarded(Agent,_,List,JobId);
		    		-awarded(Agent,_,List,JobId);
		    		.concat(List,[tool(ItemId)],NewList);
		    		+awarded(Agent,Shop,NewList,JobId);
				}
			}
			else { +initiator::impossible_task(JobId); .print("Unable to allocate tool ",ItemId); }
		}
	}
	for ( bids(item(ItemId,Qty),Bids,JobId) ) {
		if ( not initiator::impossible_task(JobId) ) {
			-bids(item(ItemId,Qty),Bids,JobId);
			?default::select_bid(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
			if (Distance \== 99999) {
				getLoad(Agent,Load);
				?default::item(ItemId,Volume,_,_);
		    	addLoad(Agent,Load-Volume*Qty);
	//	    	.print("Awarding #",Qty," of ",ItemId," to ",Agent," at",Shop);
				if (not initiator::awarded(Agent,_,_,_)) {
					+awarded(Agent,Shop,[item(ItemId,Qty)],JobId);
				}
				else {
					?awarded(Agent,_,List,JobId);
		    		-awarded(Agent,_,List,JobId);
		    		.concat(List,[item(ItemId,Qty)],NewList);
		    		+awarded(Agent,Shop,NewList,JobId);
				}
			}
			else { +initiator::impossible_task(JobId); .print("Unable to allocate #",Qty," of ",ItemId); }
		}
	}
	if (not initiator::impossible_task(JobId)) {
		?awarded_assemble(AgentA,Items,Storage,JobId);
		-awarded_assemble(AgentA,Items,Storage,JobId);
		?initiator::free_agents(FreeAgentsA);
		?initiator::free_trucks(FreeTrucksA);
		.delete(AgentA,FreeTrucksA,FreeTrucksNewA);
		-+initiator::free_trucks(FreeTrucksNewA);
		.delete(AgentA,FreeAgentsA,FreeAgentsNewA);
		-+initiator::free_agents(FreeAgentsNewA);
//		.print("Removing ",AgentA," from free lists.");
		+job_members(JobId,[]);
		for (awarded(Agent,Shop,List,JobId)) {
//			.print("Removing ",Agent," from free lists.");
			?initiator::free_agents(FreeAgents);
			.delete(Agent,FreeAgents,FreeAgentsNew);
			-+initiator::free_agents(FreeAgentsNew);
			?initiator::free_trucks(FreeTrucks);
			if (.member(Agent,FreeTrucks)) {
				.delete(Agent,FreeTrucks,FreeTrucksNew);
				-+initiator::free_trucks(FreeTrucksNew);
			}
			?job_members(JobId,Aux);
			-+job_members(JobId,[Agent|Aux]);
	    	.send(Agent,tell,winner(List,assist(Storage,AgentA)));
			-awarded(Agent,Shop,List,JobId);	
		}
		?job_members(JobId,JobMembers);
//		.print("Job members ",JobMembers);
		.send(AgentA,tell,winner(Items,assemble(Storage,JobId,JobMembers)));
		-cnp(JobId);
	}
	else { 
		-impossible_task(JobId);
		-cnp(JobId);
		-job(JobId, _, _, _);
		-job_members(JobId,_,_);
		-awarded_assemble(_,_,_,JobId);
		.abolish(initiator::bids(_,_,JobId));
		.abolish(initiator::awarded(_,_,_,JobId));
		.print("Impossible job ",JobId,", aborting it.");
	}
	?initiator::free_agents(FreeAgentsB);
	if ( .member(Me,FreeAgentsB) ) {
		!strategies::free;
	}
	.

@addAgentFree[atomic]
+!add_agent_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	.
@addTruckFree[atomic]
+!add_truck_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	-+initiator::free_trucks([Agent|FreeTrucks]);
	.
@addMeFree[atomic]
+!add_myself_to_free
	: initiator::free_agents(FreeAgents) & .my_name(Me)
<-
	-+initiator::free_agents([Me|FreeAgents]);
	.
	
@jobFinished[atomic]	
+!job_finished(JobId) 
<- 
	-initiator::job_members(JobId,_); 
	-initiator::job(JobId, _, _, _);
//	?estimate(JobId,Start,Estimate);
//	?default::step(Step);
//	.print("Finished job ",JobId," at step ",Step," estimated to end in ",Start+Estimate);
//	-estimate(JobId,Start,Estimate);
	.
	
+default::step(End)
	: mission(Id,Fine,End)
<-
	.print("!!!!!!!!!!!!!!!!! Mission ",Id," failed: deadline, paying fine of ",Fine); 
	-initiator::mission(Id,_,_); 
	.