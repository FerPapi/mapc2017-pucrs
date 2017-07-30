{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl", org) }
{ include("common-rules.asl") }
{ include("strategies/round/new-round.asl") }
{ include("strategies/common-plans.asl", strategies) }
{ include("strategies/scheme-plans.asl", org) }
{ include("strategies/bidder.asl", bidder) }
{ include("strategies/round/end-round.asl") }

+!add_initiator
<- 
	.include("strategies/initiator.asl", initiator);
	.
+!add_org_board
	: joined(org,OrgId)
<-
	create("sch.xml");
    makeArtifact(myorg, "ora4mas.nopl.OrgBoard", ["scheme/sch.xml"], OrgArtId)[wid(OrgId)];
	.	
	
+!register(E)
	: .my_name(Me)
<- 
	!new::new_round;
    .print("Registering...");
    register(E);
	.
	
+default::name(ServerMe)
	: .my_name(Me)
<-
	addServerName(Me,ServerMe);
	.
	
//+default::hasItem(Item,Qty)
//<- .print("Just got #",Qty," of ",Item).
	
+default::role(Role,_,LoadCap,_,Tools)
	: .my_name(Me) & new::tool_types(Agents)
<- 
	addLoad(Me,LoadCap);
	addRole(Me,Role);
	.wait(1000);
	if ( .member(Me,Agents) ) { .broadcast(tell,tools(Role,Tools)); }
	!strategies::free;
    .
    
+tools(Role,Tools) : default::role(Role,_,_,_,_) <- -tools(Role,Tools)[source(_)].