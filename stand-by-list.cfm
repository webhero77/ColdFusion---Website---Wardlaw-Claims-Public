<cfmodule template="/header.cfm">
<div class="sideBar">
	<cfmodule template="/sidebar.cfm">	
</div>
<div class="content">
<!-- THIS IS THE PART YOU SWAP OUT - START -->
		
	<cfobject name="variables.standByObj" component="stand_by_helper" type="component" />
	<cfset variables.publicStandByListData = variables.standByObj.getPublicStandByLists()>
			<h1>Standby Lists</h1>
					
			<h2><a href="assets/2ndTIER_TAB_ABOUTPHOTO413.jpg"><img class="aligncenter size-full wp-image-1669" title="2ndTIER_TAB_ABOUTPHOTO413" alt="Wardlaw Team" src="assets/2ndTIER_TAB_ABOUTPHOTO413.jpg" width="609" height="272" /></a></h2>		
			<br/><br/>
			<!--- Get PUBLIC stand by lists and display them as links --->
			<cfoutput query="variables.publicStandByListData">
			
				<div class="cfoutputs">				
				<b><a href="stand-by-list-register.cfm?e=#variables.publicStandByListData.list_id#">#variables.publicStandByListData.list_name#</b></a><br/>
				#variables.publicStandByListData.Comments#<br/><br/>
				
				</div>
			
			</cfoutput>
			</div>
			
			
			
<!-- THIS IS THE PART YOU SWAP OUT - END -->
</div>

<cfmodule template="/footer.cfm">	