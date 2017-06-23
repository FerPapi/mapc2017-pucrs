{ include("action/actions.asl",action) }
free.

+default::actionID(0) 
<-
	.wait({ +coalition::coalition(Quad,NewCoalition,Task) });
	!action::skip;
	.
+default::actionID(X) 
	: free
<-
	!action::skip;
	.

//+coalition::coalition(Quad, Members, Task)
//	: true
//<- 
////	if (Quad == 1) {.print("I am in coalition 1.")}; if (Quad == 2) {.print("I am in coalition 2.")}; if (Quad == 3) {.print("I am in coalition 3.")}; if (Quad == 4) {.print("I am in coalition 4.")};
//	.wait ({ +default::step(0) });
//	if (Task == explore) {-free; !explore(Quad)};
//	if (Task == shop) {-free; !exploreShop(Quad)};
////	if (Task == first) {+free; !action::skip};
////	if (Task == second) {+free; !action::skip};
//	if (Task == workshop) {-free; !exploreWorkshop(Quad)};
////	if (Task == resource) {if(not gathering) {+free; .print("free"); !action::skip}};
//.

+!exploreShop(Quad)
	: default::role(Role, _, _, _, _) & new::shopList(List)
<- 
	if (Quad == 1) {?coalition::quad1(Lat,Lon)};
	if (Quad == 2) {?coalition::quad2(Lat,Lon)};
	if (Quad == 3) {?coalition::quad3(Lat,Lon)};
	if (Quad == 4) {?coalition::quad4(Lat,Lon)};
	actions.closest(Role,Lat,Lon,List,ClosestShop);
	!action::goto(ClosestShop);
	?default::step(S);
	.print("Finished my exploration at step ",S);
	+free; 
	!action::skip;
	.
+!exploreWorkshop(Quad)
	: default::role(Role, _, _, _, _) & new::workshopList(List)
<- 
	if (Quad == 1) {?coalition::quad1(Lat,Lon)};
	if (Quad == 2) {?coalition::quad2(Lat,Lon)};
	if (Quad == 3) {?coalition::quad3(Lat,Lon)};
	if (Quad == 4) {?coalition::quad4(Lat,Lon)};
	actions.closest(Role,Lat,Lon,List,ClosestWorkshop);
	!action::goto(ClosestWorkshop);
	?default::step(S);
	.print("Finished my exploration at step ",S);
	+free; 
	!action::skip;
	.
+!explore(Quad)
	: coalition::minLonReal(MinLon) & coalition::maxLonReal(MaxLon) & coalition::minLatReal(MinLat) & coalition::maxLatReal(MaxLat) & coalition::mapCenter(CenterLat,CenterLon) //& coalition::quad1(LatQ1,LonQ1) & coalition::quad2(LatQ2,LonQ2) & coalition::quad3(LatQ3,LonQ3) & coalition::quad4(LatQ4,LonQ4)
<- 
	if (Quad == 1) {
		!action::goto(CenterLat,MinLon);
		!action::goto(MaxLat,MinLon);
		!action::goto(MaxLat,CenterLon);
		!action::goto(CenterLat,CenterLon);
	}
	if (Quad == 2) {
		!action::goto(MaxLat,CenterLon);
		!action::goto(MaxLat,MaxLon);
		!action::goto(CenterLat,MaxLon);
		!action::goto(CenterLat,CenterLon);
		
	}
	if (Quad == 3) {
		!action::goto(CenterLat,CenterLon);
		!action::goto(CenterLat,MinLon);
		!action::goto(MinLat,MinLon);
		!action::goto(MinLat,CenterLon);
	}
	if (Quad == 4) {
		!action::goto(CenterLat,CenterLon);
		!action::goto(MinLat,CenterLon);
		!action::goto(MinLat,MaxLon);
		!action::goto(CenterLat,MaxLon);
	}
	?default::step(S);
	.print("Finished my exploration at step ",S);
	+free; 
	!action::skip;
	.
+!exploreTools
	: default::role(Role, Speed, _, _, Tools) & (Role == motorcycle) & new::shopList(List)
<- 
	?myquad(Q);
	if (Q == 1) {?coalition::quad1(Lat,Lon)};
	if (Q == 2) {?coalition::quad2(Lat,Lon)};
	if (Q == 3) {?coalition::quad3(Lat,Lon)};
	if (Q == 4) {?coalition::quad4(Lat,Lon)};
	for ( .member(Tool,Tools) ) {
		?default::find_shops(Tool,List,Shops);
		actions.closest(Role,Lat,Lon,Shops,ClosestShop);
		+buyList(Tool,1,ClosestShop);
	}
	!goBuy;
	?default::step(S);
	.print("Finished my exploration at step ",S);
	+free; 
	!action::skip;
	.

+!goBuy
	: buyList(_,_,Shop)
<-
	.print("Going to shop ",Shop);
	!action::goto(Shop);
	for ( buyList(Tool,Qty,Shop) ) {
		!action::buy(Tool,Qty);
		.print("Buying #",Qty," of ",Tool);
		-buyList(Tool,Qty,Shop);
	}
	!gotoShops
	.
+!gotoShops.

//+default::resNode(ResourceId,Lat,Lon,Resource)
//	: .my_name(Me) & coalition::coalition(Quad, Me, resource) & not gathering & default::checkQuadrant(Quad,Lat,Lon) & .term2string(ResT,Resource) & default::item(ResT,Vol,_,_)
//<-
//	-free;
//	+gathering;
//	.print("Resource ",ResourceId," is in my quadrant, moving to gather.");
//	!action::goto(Lat,Lon);
//	?default::step(S);
//	.print("Arrived at ",ResourceId," in step ",S);
//	!action::gather(Vol);
//	+free;
//	!action::skip;
//	.

+default::lastAction(Action)
	: default::step(S) & S \== 0 & Action == noAction & new::noActionCount(Count)
<-
	-+new::noActionCount(Count+1);
	.print(">>>>>>>>>>> I have done ",Count+1," noActions.");
	.
	
//+default::hasItem(Item,Qty)
//<- .print("I now have #",Qty," of item ",Item).

+default::resourceNode(ResourceId,Lat,Lon,Resource)
	: .term2string(ResourceId,ResourceId2) & not default::resNode(ResourceId2,_,_,_)
<- 
	.print("Detected new resource node ",ResourceId," with resource ",Resource);
	-default::resourceNode(ResourceId,Lat,Lon,Resource);
	addResourceNode(ResourceId,Lat,Lon,Resource);
	.