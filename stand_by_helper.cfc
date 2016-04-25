<!---


Requiress cds_string_helper.cfc in CustomTags directory, uses CreateMsGuid and StripHtml methods

Changes

2015-01-05
* refactor to avoid SQL injection attacks by adding cfqueryparam

2015-12-20
* added condition to avoid sending test submissions to current users
--->


<cfcomponent output="no" hint="Collection of methods for working with stand by lists">

	<!---
	Queries DB for PUBLIC stand by List
	Uses cfaccount2005 datasource
	--->

	<cffunction name="getPublicStandByLists" returntype="query" access="public" output="no" hint="Get publicly visible stand by lists">
		<cfargument name="listId" type="guid" required="no" default="00000000-0000-0000-0000-000000000000" hint="If specified, returns only record for specified event" />		
		<cfargument name="memberId" type="guid" required="no" default="00000000-0000-0000-0000-000000000000" hint="If specified, returns only lists on which specified member id occurs" /> 		

		<cfset var local=StructNew() />
		
		<cfquery name="local.listData" datasource="cfaccount2005">
			SELECT
				L.List_Id,
				L.List_Name,
				L.Comments
			FROM HR.dbo.Stand_By_Lists AS L
			WHERE L.Public_Active = <cfqueryparam value="1" cfsqltype="cf_sql_bit" />  
				<cfif arguments.listId neq "00000000-0000-0000-0000-000000000000">
					AND L.List_Id = <cfqueryparam value="#arguments.listId#" cfsqltype="cf_sql_char" />
				</cfif>

				<cfif arguments.memberId neq "00000000-0000-0000-0000-000000000000">
					AND EXISTS 
						(
						SELECT *
						FROM HR.dbo.Stand_By_List_Members AS M
						WHERE M.List_Id = L.List_Id
							AND M.Member_Id = <cfqueryparam value="#arguments.memberId#" cfsqltype="cf_sql_char" />
							AND M.Removed_From_Stand_By = 0
						)
				</cfif>

			ORDER BY L.List_Name;
		</cfquery>

		<cfreturn local.listData />

	</cffunction>
	
	
	<!---
	Queries DB for PRIVATE stand by List
	Uses cfaccount2005 datasource
	--->
	<cffunction name="getPrivateStandByLists" returntype="query" access="public" output="no" hint="Get publicly visible stand by lists">
		<cfargument name="listId" type="guid" required="no" default="00000000-0000-0000-0000-000000000000" hint="If specified, returns only record for specified event" />		
		<cfargument name="memberId" type="guid" required="no" default="00000000-0000-0000-0000-000000000000" hint="If specified, returns only lists on which specified member id occurs" /> 		

		<cfset var local=StructNew() />
		
		<cfquery name="local.listData" datasource="cfaccount2005">
			SELECT
				L.List_Id,
				L.List_Name,
				L.Comments
			FROM HR.dbo.Stand_By_Lists AS L
			WHERE L.Private_Active = <cfqueryparam value="1" cfsqltype="cf_sql_bit" />  
				<cfif arguments.listId neq "00000000-0000-0000-0000-000000000000">
					AND L.List_Id = <cfqueryparam value="#arguments.listId#" cfsqltype="cf_sql_char" />
				</cfif>

				<cfif arguments.memberId neq "00000000-0000-0000-0000-000000000000">
					AND EXISTS 
						(
						SELECT *
						FROM HR.dbo.Stand_By_List_Members AS M
						WHERE M.List_Id = L.List_Id
							AND M.Member_Id = <cfqueryparam value="#arguments.memberId#" cfsqltype="cf_sql_char" />
							AND M.Removed_From_Stand_By = 0
						)
				</cfif>

			ORDER BY L.List_Name;
		</cfquery>

		<cfreturn local.listData />

	</cffunction>
		

	<!---
	Utility function determines if supplied email has Wardlaw domain
	--->
	<cffunction name="isValidWardlawEmailAddress" returntype="boolean" access="public" output="no" hint="Checks if Wardlaw email address matches record in HR database">
		<cfargument name="emailAddress" type="string" required="yes" />

		<cfset var local=StructNew() />

		<cfset local.retVal=false />
		
		<cfif IsValid("email", arguments.emailAddress)>

			<cfif ListLast(arguments.emailAddress, "@") eq "wardlawclaims.com">
	
				<!--- see if there is a Personal ID matching the email address --->				
				<cfset local.pid=getPersonalIdFromWardlawEmailAddress(arguments.emailAddress) />

				<cfif local.pid neq "">
					<cfset local.retVal=true />
				</cfif>

			</cfif>

		</cfif>


		<cfreturn local.retVal />
	</cffunction>


	<!---
	Queries DB for personal ID via a valid Wardlaw Email Address
	Uses cfaccount2005 datasource
	--->
	<cffunction name="getPersonalIdFromWardlawEmailAddress" returntype="string" access="public" output="no" hint="Gets Personal ID based on Wardlaw email address, if not found returns empty string">
		<cfargument name="wardlawEmail" type="string" required="yes" />

		<cfset var local=StructNew() />

		<cfset local.retVal="" />

		<cfquery name="local.idData" datasource="cfaccount2005">
			SELECT Personal_ID
			FROM HR.dbo.People
			WHERE Wardlaw_Email = <cfqueryparam value="#arguments.wardlawEmail#" cfsqltype="cf_sql_varchar" /> 
		</cfquery>

		<cfif local.idData.recordCount eq 1>
			<cfset local.retVal=local.idData.Personal_ID />
		</cfif>

		<cfreturn local.retVal />

	</cffunction>


	<!---
	Inputs contact into Stand By list from supplied form info (long form), denotes a new user
	Uses cfaccount2005 datasource
	--->
	<cffunction name="addContactInfoToStandByList" returntype="void" access="public" hint="Add contact infomation to stand by list">
		<cfargument name="listId" type="guid" required="yes" hint="Specifies list to add to" />
		<cfargument name="lastName" type="string" required="yes" />
		<cfargument name="firstName" type="string" required="yes" />
		<cfargument name="streetAddress1" type="string" required="yes" />
		<cfargument name="streetAddress2" type="string" required="yes" />
		<cfargument name="city" type="string" required="yes" />
		<cfargument name="state" type="string" required="yes" />
		<cfargument name="zipCode" type="string" required="yes" />
		<cfargument name="personalEmail" type="string" required="yes" />
		<cfargument name="cellularPhone" type="string" required="yes" />
		<cfargument name="otherPhone" type="string" required="yes" />
		<cfargument name="comments" type="string" required="no" default="" />
		<cfargument name="sendConfirmationEmail" type="boolean" required="no" default="true" hint="Should a confirmation email be sent, defaults to true" />
		<cfargument name="listStatus" type="string" required="yes" default="" hint="listStatus should be public or private" />		

		<cfset var local=StructNew() />

		<cfobject name="local.stringObj" component="cds_string_helper" type="component" /> 

		<cfset local.newMemberId=local.stringObj.CreateMsGuid() />

		<!--- set options required since we are touching a table with an indexed view --->
		<cfquery name="local.setOptionsQry" datasource="cfaccount2005">
			SET ANSI_NULLS ON
			SET ANSI_PADDING ON
			SET ANSI_WARNINGS ON
			SET CONCAT_NULL_YIELDS_NULL ON
			SET NUMERIC_ROUNDABORT OFF
			SET QUOTED_IDENTIFIER ON
			SET ARITHABORT ON
		</cfquery>

		<!--- add adjuster to list --->
			<cfquery name="local.insertStandBy" datasource="cfaccount2005">
				INSERT INTO HR.dbo.Stand_By_List_Members ( List_Id, Member_Id, Comments, Last_Name, First_Name, Street_Address_1, Street_Address_2, City, [State], Zip_Code, Personal_Email, Cellular_Phone, Other_Phone )
				VALUES
					(
					<cfqueryparam value="#arguments.listId#" cfsqltype="cf_sql_char"  /> , 
					<cfqueryparam value="#local.newMemberId#" cfsqltype="cf_sql_char"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.comments))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.lastName))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.firstName))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.streetAddress1))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.streetAddress2))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.city))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.state))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.zipCode))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.personalEmail))#" cfsqltype="cf_sql_varchar"  /> , 
					<cfqueryparam value="#ReReplaceNoCase(arguments.cellularPhone, '\D', '', 'ALL')#" cfsqltype="cf_sql_varchar"  /> , <!--- strip non-digit characters from phone numbers --->
					<cfqueryparam value="#ReReplaceNoCase(arguments.otherPhone, '\D', '', 'ALL')#" cfsqltype="cf_sql_varchar"  />
					);			
			</cfquery>

			<!--- send confirmation email --->
			<cfif arguments.sendConfirmationEmail and IsValid("email", arguments.personalEmail)>
		
				<cfinvoke method="sendConfirmationEmail">
					<cfinvokeargument name="emailTo" value="#arguments.personalEmail#" />
					<cfinvokeargument name="listId" value="#arguments.listId#" />
					<cfinvokeargument name="memberId" value="#local.newMemberId#" />
					<cfinvokeargument name="listStatus" value="#arguments.listStatus#" />
				</cfinvoke>

			</cfif>

	</cffunction>


	<!---
	Inputs contact into Stand By list from the supplied Wardlaw email, denotes an existing user
	Uses cfaccount2005 datasource
	--->	
	<cffunction name="addWardlawAdjusterToStandByList" returntype="void" access="public" hint="Adds adjuster to stand by list based on Wardlaw email address">
		<cfargument name="listId" type="guid" required="yes" hint="Specifies list to add to" />
		<cfargument name="wardlawEmail" type="string" required="yes" />
		<cfargument name="comments" type="string" required="no" default="" hint="Comments to include" />
		<cfargument name="sendConfirmationEmail" type="boolean" required="no" default="true" hint="Should a confirmation email be sent, defaults to true" />
		<cfargument name="listStatus" type="string" required="yes" default="" hint="The Standby list should be either public or private" />


		<cfset var local=StructNew() />

		<cfobject name="local.stringObj" component="cds_string_helper" type="component" /> 


		<!--- get personal id --->
		<cfset local.pid=getPersonalIdFromWardlawEmailAddress(arguments.wardlawEmail) />

		<cfif local.pid eq "">
			<cfthrow message="Invalid Wardlaw email used to register for stand by list: #arguments.wardlawEmail#" />
			<cfabort />
		</cfif>

		

		<!--- verify adjuster not already on list --->
		<cfif not isAdjusterOnStandByList(personalId=local.pid, listId=arguments.listId)>

			<cfset local.newMemberId=local.stringObj.CreateMsGuid() />

			<!--- set options required since we are touching a table with an indexed view --->
			<cfquery name="local.setOptionsQry" datasource="cfaccount2005">
				SET ANSI_NULLS ON
				SET ANSI_PADDING ON
				SET ANSI_WARNINGS ON
				SET CONCAT_NULL_YIELDS_NULL ON
				SET NUMERIC_ROUNDABORT OFF
				SET QUOTED_IDENTIFIER ON
				SET ARITHABORT ON
			</cfquery>

			<!--- add adjuster to list --->
			<cfquery name="local.insertStandBy" datasource="cfaccount2005">
				INSERT INTO HR.dbo.Stand_By_List_Members ( List_Id, Member_Id, Personal_Id, Comments )
				VALUES
					(
					<cfqueryparam value="#arguments.listId#" cfsqltype="cf_sql_char" /> ,
					<cfqueryparam value="#local.newMemberId#" cfsqltype="cf_sql_char" /> ,
					<cfqueryparam value="#local.pid#" cfsqltype="cf_sql_varchar" /> ,
					<cfqueryparam value="#Trim(local.stringObj.StripHtml(arguments.comments))#" cfsqltype="cf_sql_varchar" />
					);
			</cfquery>

			<!--- send confirmation email --->
			<cfif arguments.sendConfirmationEmail>
		
				<cfinvoke method="sendConfirmationEmail">
					<cfinvokeargument name="emailTo" value="#arguments.wardlawEmail#" />
					<cfinvokeargument name="listId" value="#arguments.listId#" />
					<cfinvokeargument name="memberId" value="#local.newMemberId#" />
					<cfinvokeargument name="listStatus" value="#arguments.listStatus#" />
				</cfinvoke>

			</cfif>

		</cfif>

		

	</cffunction>



	<!---
	Composes and sends confirmation email to applicant
	--->
	<cffunction name="sendConfirmationEmail" returntype="void" access="public" output="no" hint="Send a confirmation email to adjuster that he/she has been added to stand by list, includes removal link">
		<cfargument name="emailTo" type="string" required="yes" hint="Address to mail to" />
		<cfargument name="listId" type="guid" required="yes" hint="Specifies stand by list" />
		<cfargument name="memberId" type="guid" required="yes" hint="Specifies list member id" />
		<cfargument name="listStatus" type="string" required="yes" hint="Specifies a public or private list" />

		<cfset var local=StructNew() />

		<cfif not IsValid("email", arguments.emailTo)>
			<cfreturn />
		</cfif>

		<!--- lookup stand by list --->
		<cfif arguments.listStatus eq "public">
			<cfset local.listData=getPublicStandByLists(listId=arguments.listId) />
	  <cfelse>
			<cfset local.listData=getPrivateStandByLists(listId=arguments.listId) />
		</cfif>

		<cfset local.listName=local.listData.List_Name />

		<!--- construct remove link --->
		<cfif arguments.listStatus eq "public">
			<cfset local.removeUrl="http://#cgi.server_name#/stand-by-list-remove.cfm?s=#arguments.memberId#" />
		</cfif>		
		
		
		
		<!--- if this is a dev server override mail to ---> 
		<cfset local.mailTo=arguments.emailTo />
		<cfif (cgi.server_name eq "wardlawclaims") or (cgi.server_name eq "localhost") or (cgi.server_name eq "127.0.0.1")>
			<cfset local.mailTo="adrian@wardlawclaims.com" />
		</cfif>

		<cfif arguments.listStatus eq "public">
			<cfmail from="webmaster@wardlawclaims.com" to="#local.mailTo#" subject="Stand By List for #local.listName#" type="html">
				<html>
					<head>
						<style type="text/css">
							body 
								{ 
									font-family: arial, sans-serif; 
								}
						</style>
					</head>
				<body>
				You have been added to the stand by list for #HtmlEditFormat(local.listName)#.
				<p>If you wish to be removed from this stand by list visit the following link <a href="#local.removeUrl#">#local.removeUrl#</a></p>
				</body>
				</html>
			</cfmail>
		<cfelse>
			<cfmail from="webmaster@wardlawclaims.com" to="#local.mailTo#" subject="#local.listName#" type="html">
				<html>
					<head>
						<style type="text/css">
							body 
								{ 
									font-family: Tahoma, sans-serif, arial; 
								}
						</style>
					</head>
				<body>
				<p><img src="assets/L_and_L_header.jpg" /></p>
				<p>Dear Adjuster:</p>
				<p>Congratulations!! You are officially “Locked and Loaded” with Wardlaw for the 2010 Season.</p>
				<p>
						Thank you for signing up on our <strong>Hurricane Season 2016 Availability List</strong>.  
						Should we have a hurricane with a subsequent deployment, you will be the first to know.  
						In that case, we will be communicating with you by email or phone as we construct our response to the storm.  
						You will receive more detailed information at that time depending on the size, location, and timing of the storm.
				</p>
				<p>In the meantime, you are “Locked and Loaded” with Wardlaw.</p>
				<table border=0 cellspacing=0 cellpadding=0 width=611>
					<tr>
						<td>William F. Wardlaw</td>
						<td rowspan="3" align="right"><img src="assets/wcslogo.bmp"></td>
					</tr>
					<tr>
						<td>Partner</td>
					</tr>
					<tr>
						<td>Wardlaw Claims Service</td>
					</tr>								
				</table>
				</body>
				</html>
				</cfmail>
		</cfif>
	</cffunction>
	

	<!---
	Queries specified stand by list to find submissions for current personal ID
	Uses cfaccount2005 datasource
	--->
	<cffunction name="isAdjusterOnStandByList" returntype="boolean" access="public" output="no" hint="Checks if adjuster is on a specified stand by list">
		<cfargument name="personalId" type="string" required="yes" hint="Personal ID of adjuster to check" />
		<cfargument name="listId" type="guid" required="yes" hint="Stand by list to check" />

		<cfset var local=StructNew() />

		<cfset local.retVal=false />

		<cfquery name="local.standByData" datasource="cfaccount2005">
			SELECT Member_Id
			FROM HR.dbo.Stand_By_List_Members
			WHERE List_Id = <cfqueryparam value="#arguments.listId#" cfsqltype="cf_sql_char" /> 
				AND Personal_ID = <cfqueryparam value="#arguments.personalId#" cfsqltype="cf_sql_varchar" /> 
		</cfquery>

		<cfif local.standByData.recordCount gt 0>
			<cfset local.retVal=true />
		</cfif>

		<cfreturn local.retVal /> 
 
	</cffunction>


	<!---
	Updates submission for stand by list for specified personal ID and sets it to inactive (Removed_From_Stand_By=1)
	Uses cfaccount2005 datasource
	--->
	<cffunction name="removeAdjusterFromStandBy" returntype="void" output="no" access="public" hint="Remove member from stand by list">
		<cfargument name="memberId" type="guid" required="yes" hint="Specifies Member_ID in stand by list" /> 		

		<cfset var local=StructNew() />

		<!--- set options required since we are touching a table with an indexed view --->
		<cfquery name="local.setOptionsQry" datasource="cfaccount2005">
			SET ANSI_NULLS ON
			SET ANSI_PADDING ON
			SET ANSI_WARNINGS ON
			SET CONCAT_NULL_YIELDS_NULL ON
			SET NUMERIC_ROUNDABORT OFF
			SET QUOTED_IDENTIFIER ON
			SET ARITHABORT ON
		</cfquery>
	
		<cfquery name="local.updateQry" datasource="cfaccount2005">
			UPDATE HR.dbo.Stand_By_List_Members
			SET Removed_From_Stand_By = 1
			WHERE Member_ID = <cfqueryparam value="#arguments.memberId#" cfsqltype="cf_sql_char" /> 
				AND Removed_From_Stand_By = 0; 
		</cfquery>

	</cffunction>
	

</cfcomponent>