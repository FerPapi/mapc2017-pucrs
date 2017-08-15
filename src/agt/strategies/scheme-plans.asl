+goalState(JobId,job_delivered,_,_,satisfied)
	: default::winner(_, assemble(_, JobId))
<-
//   .print("*** all done! ***");
   removeScheme(JobId);
   .abolish(org::_);
   .

+!go_to_workshop
	: default::winner(_, assemble(Storage, _))
<-
	!strategies::go_to_workshop(Storage);
	!!strategies::free;
	.

+!do_assemble
	: default::winner(TaskList, assemble(_, _)) & default::get_assemble(TaskList, [], AssembleListNotSorted, 0)
<-
	!strategies::not_free;
	.sort(AssembleListNotSorted,AssembleList);
//	.print("Assemble List ",AssembleList);
	for ( .member(item(_,ItemId,Qty),AssembleList) ) {
		for ( .range(I,1,Qty) ) {
//			.print("trying to assemble ",ItemId);
			!action::assemble(ItemId);
		} 
	}
	!!strategies::go_deliver;
	.

+!buy_items
	: default::role(Role, _, _, _, _) & new::shopList(SList) & default::winner(TaskList, assist(Storage, _, _)) & .my_name(Me)
<-
	for ( .member(tool(ItemId),TaskList) ) {
		.findall(StorageAdd,default::available_items(StorageS,AvailableT) & .term2string(ItemId,ToolS) & .substring(ToolS,AvailableT) & .term2string(StorageAdd,StorageS), StorageList);
		if ( StorageList \== [] ) {
			actions.closest(Role,StorageList,Facility);
			removeAvailableItem(Facility,ItemId,1);
			+strategies::retrieveList(ItemId,1,Facility);
		}
		else {
			?default::find_shops(ItemId,SList,Shops);
			actions.closest(Role,Shops,ClosestShop);
			+strategies::buyList(ItemId,1,ClosestShop);
		}
	}
	for ( .member(item(ItemId,Qty),TaskList) ) {
		?default::find_shop_qty(item(ItemId, Qty),SList,Buy,99999,RouteShop,99999,"",Shop);
		if (strategies::buyList(ItemId,Qty2,Shop)) {
			-strategies::buyList(ItemId,Qty2,Shop)
			+strategies::buyList(ItemId,Qty+Qty2,Shop);
		}
		else { +strategies::buyList(ItemId,Qty,Shop); }
	}
	+strategies::buy_list_id(0);
	for ( strategies::buyList(ItemId,Qty,Shop) ) {
		getShopItem(item(Shop,ItemId),QtyCap);
		-strategies::buyList(ItemId,Qty,Shop);
		if (Qty > QtyCap) {
//			.print("Need to buy #",Qty," of ",ItemId," from ",Shop," cap ",QtyCap);
			for ( .range(I,1,math.floor(Qty/QtyCap)) ) {
				?strategies::buy_list_id(Id);
				-+strategies::buy_list_id(Id+1);
				+strategies::buyList(ItemId,QtyCap,Shop,Id+1);
//				.print("Adding buylist #",QtyCap," ",ItemId);
			}
			Mod = Qty mod QtyCap;
			if ( Mod \== 0 ) {
				?strategies::buy_list_id(Id);
				-+strategies::buy_list_id(Id+1);
				+strategies::buyList(ItemId,Mod,Shop,Id+1);
//				.print("Adding buylist #",Mod," ",ItemId);
			}
		}
		else { ?strategies::buy_list_id(Id); -+strategies::buy_list_id(Id+1); +strategies::buyList(ItemId,Qty,Shop,Id+1);  }
	}
	-strategies::buy_list_id(_);
	!strategies::go_buy;
	if (strategies::retrieveList(_,_,Fac)) {
		for ( strategies::retrieveList(ItemId,Qty,Fac) ) {
			!action::goto(Fac);
			-strategies::retrieveList(ItemId,Qty,Fac);
			!action::retrieve(ItemId,Qty);
		}
	}
	!strategies::go_to_workshop(Storage);
	if (Me == vehicle1) { +strategies::waiting; }
	!!check_state;
	.
	
+!check_state : not goalState(JobId,phase1,_,_,satisfied) <- !!strategies::free.
+!check_state.
	
+!assist_assemble
	: default::winner(_, assist(_, Assembler, _)) & .my_name(Me)
<-
	if (Me == vehicle1) { -strategies::waiting; }
	!strategies::not_free;
	+strategies::assembling;
	!!action::assist_assemble(Assembler);
	.
	
+!stop_assist_assemble
	: default::winner(_,_)
<-
	-strategies::assembling;
	-default::winner(_,_)[source(_)];
//	!!strategies::empty_load;
	!!strategies::empty_load;
	.
+!stop_assist_assemble <- .print("!!!!!!!!!!!!! Received stop assist from scheme but did not have the winner belief anymore.").