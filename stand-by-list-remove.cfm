<cfmodule template="/header.cfm">
<div class="sideBar">
	<cfmodule template="/sidebar.cfm">	
</div>
<div class="content">
<!-- THIS IS THE PART YOU SWAP OUT - START -->

	<!---	Ensures submission is viable, s OR ps variables defined along with a valid GUID	--->
	<cfif (not IsDefined("url.s") or not IsValid("guid", url.s)) and (not IsDefined("url.ps") or not IsValid("guid", url.ps)) >
		<cfabort />
	</cfif>

	<cfif IsDefined("url.s") and IsValid("guid",url.s)>
		<cfset myliststatus = "public">
	<cfelse>
		<cfset myliststatus = "private">
	</cfif>

	<!---	Get list information based on myliststatus value	--->
	<cfif myliststatus eq "public">
		<cfinvoke component="stand_by_helper" method="getPublicStandByLists" returnvariable="variables.listData">
			<cfinvokeargument name="memberId" value="#url.s#" />
		</cfinvoke>
	<cfelse>	
		<cfinvoke component="stand_by_helper" method="getPrivateStandByLists" returnvariable="variables.listData">
			<cfinvokeargument name="memberId" value="#url.ps#" />
		</cfinvoke>
	</cfif>

	<!---	Results, no records	--->
	<cfif variables.listData.recordCount lte 0>
		NO RECORD FOUND
		<cfabort />
	</cfif>

	<!--- 	Default variables.completed to false, used on output	--->
	<cfset variables.completed=false /> 

	<!--- Invokes method, must come from a form, sets  --->
	<cfif IsDefined("form.removeSbmt")>
		<cfif myliststatus eq "public">
			<cfinvoke component="stand_by_helper" method="removeAdjusterFromStandBy">
				<cfinvokeargument name="memberId" value="#url.s#" />
			</cfinvoke>
		<cfelse>
				<cfinvoke component="stand_by_helper" method="removeAdjusterFromStandBy">
				<cfinvokeargument name="memberId" value="#url.ps#" />
			</cfinvoke>
		</cfif>
		<!--- 		Default variables.completed to false, used on output		--->
		<cfset variables.completed=true />
	</cfif>

	<!--- Displays result  --->
	<cfoutput>
		<cfif not variables.completed>
			<h1>#HtmlEditFormat(variables.listData.List_Name)#</h1><br/>
			<cfif myliststatus eq "public">
				<form id="removeFrm" name="removeFrm" method="post" action="stand-by-list-remove.cfm?s=#UrlEncodedFormat(url.s)#">
					<input type="submit" id="removeSbmt" name="removeSbmt" value="Please remove me from the standby list" />
				</form>
			<cfelse>
				<form id="removeFrm" name="removeFrm" method="post" action="stand-by-list-remove.cfm?ps=#UrlEncodedFormat(url.ps)#">
					<input type="submit" id="removeSbmt" name="removeSbmt" value="Please remove me from the standby list" />
				</form>
			</cfif>
		<cfelse>
			<h3>You have been removed from the standby list</h3>
		</cfif>
	</cfoutput>




<!-- THIS IS THE PART YOU SWAP OUT - END -->
</div>

<cfmodule template="/footer.cfm">	