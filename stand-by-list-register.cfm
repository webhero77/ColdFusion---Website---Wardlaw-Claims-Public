<cfmodule template="/header.cfm">
<div class="sideBar">
<cfmodule template="/sidebar.cfm">	

</div>


<div class="content">
<!-- THIS IS THE PART YOU SWAP OUT - START -->
		
	<!--- initializing variables --->
	<cfobject name="variables.stringHelperObj" component="cds_string_helper" />
	<cfobject name="variables.standByObj" component="stand_by_helper" type="component" />
	<cfset variables.listData = variables.standByObj.getPublicStandByLists()>

	<!--- 	Default variables.completed to false, used on output	--->	
	<cfset variables.completed=false />

	<cfparam name="url.em" default="" />

	<cfif not IsValid("email", url.em) or ListLast(url.em, "@") neq "wardlawclaims.com">
		<cfset url.em="" />
	</cfif>

	<cfset sbl_type = "">
	<cfobject name="variables.standByObj" component="stand_by_helper" type="component" />

	<cfif IsDefined("url.sbl") and IsValid("guid",url.sbl)>
		<cfset sbl_type = "private">
	</cfif>

	<cfif IsDefined("url.e") and IsValid("guid", url.e)>
		<cfset sbl_type = "public">
	</cfif>


	<cfif sbl_type eq "">
		<cflocation url="index.cfm" />
		<cfabort />
	</cfif>

	<cfif sbl_type eq "public">
		<cfinvoke component="#variables.standByObj#" method="getPublicStandByLists" returnvariable="variables.listData">
			<cfinvokeargument name="listId" value="#url.e#" />
		</cfinvoke>
	<cfelse>
		<cfinvoke component="#variables.standByObj#" method="getPrivateStandByLists" returnvariable="variables.listData">
			<cfinvokeargument name="listId" value="#url.sbl#" />
		</cfinvoke>
	</cfif>


	<cfif variables.listData.recordCount lte 0>
		<cflocation url="index.cfm" />
		<cfabort />
	</cfif>


	<!--- list of states includes Canadian provinces --->
	<cfset variables.stateList="AK,AL,AR,AZ,CA,CO,CT,DC,DE,FL,GA,HI,IA,ID,IL,IN,KS,KY,LA,MA,MD,ME,MI,MN,MO,MS,MT,NC,ND,NE,NH,NJ,NM,NV,NY,OH,OK,OR,PA,RI,SC,SD,TN,TX,UT,VA,VT,WA,WI,WV,WY,AB,BC,MB,NB,NL,NS,NT,NU,ON,PE,QC,SK,YT" />

	<cfset variables.wardlawErrorSet=ArrayNew(1) />
	<cfset variables.newErrorSet=ArrayNew(1) />

	<!---
		Determine which form was submitted - Wardlaw email registration
	--->
	<cfif IsDefined("form.wardlawSbmt")>
		<cfparam name="form.wcsEmail" type="email"> 
		
		<!--- verify required form fields submitted --->
		<cfinvoke component="validation_helper" method="CheckStructKeyExistsForList" returnvariable="variables.missingSet">
			<cfinvokeargument name="targetStruct" value="#form#" />
			<cfinvokeargument name="keyList" value="wcsEmail" />
		</cfinvoke>

		<cfif ArrayLen(variables.missingSet) gt 0>
			INVALID PARAMETERS
			<cfabort />
		</cfif>

		<cfif not variables.standByObj.isValidWardlawEmailAddress(Trim(form.wcsEmail))>
			<cfset ArrayAppend(variables.wardlawErrorSet, "The email address you entered does not exist in our database, either it was not spelled correctly or does not exist. Please check the spelling. If you do not have a Wardlaw email address please enter your contact information below in the section labeled 'Join standby list by submitting your contact information'") />
		</cfif>

		<cfif Len(Trim(form.comments)) gt 255>
			<cfset ArrayAppend(variables.wardlawErrorSet, "Please enter Comments of 255 or fewer characters or leave blank") />
		</cfif>
		
		<cfif ArrayLen(variables.wardlawErrorSet) eq 0>

			
			
			<!--- save data --->
			<cfinvoke component="#variables.standByObj#" method="addWardlawAdjusterToStandByList">
				<cfif sbl_type eq "public">
					<cfinvokeargument name="listId" value="#url.e#" />
				<cfelse>
					<cfinvokeargument name="listId" value="#url.sbl#" />
				</cfif>
				<cfinvokeargument name="wardlawEmail" value="#Trim(form.wcsEmail)#" />
				<cfinvokeargument name="comments" value="#variables.stringHelperObj.StripHtml(Trim(form.comments))#" />
				<cfif sbl_type eq "public">
					<cfinvokeargument name="listStatus" value="public" />
				<cfelse>
					<cfinvokeargument name="listStatus" value="private" />
				</cfif>	
			</cfinvoke>
				
			<cfset variables.completed=true />
		</cfif>
	
	<!---
		Determine which form was submitted - New registrant
	--->
	<cfelseif IsDefined("form.newSbmt")>

		<!--- verify required form fields submitted --->
		<cfinvoke component="validation_helper" method="CheckStructKeyExistsForList" returnvariable="variables.missingSet">
			<cfinvokeargument name="targetStruct" value="#form#" />
			<cfinvokeargument name="keyList" value="firstName,lastName,street1,street2,city,state,zipCode,personalEmail,cellularPhone,otherPhone,comments" />
		</cfinvoke>

		<cfif ArrayLen(variables.missingSet) gt 0>
			INVALID PARAMETERS
			<cfabort />
		</cfif>

		<!--- server side validation --->
		<cfif variables.stringHelperObj.StripHtml(Trim(form.firstName)) eq "">
			<cfset ArrayAppend(variables.newErrorSet, "Please enter First Name") />
		</cfif>

		<cfif variables.stringHelperObj.StripHtml(Trim(form.lastName)) eq "">
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Last Name") />
		</cfif>

		<cfif variables.stringHelperObj.StripHtml(Trim(form.street1)) eq "">
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Street Address") />
		</cfif>
		
		<cfif variables.stringHelperObj.StripHtml(Trim(form.city)) eq "">
			<cfset ArrayAppend(variables.newErrorSet, "Please enter City") />
		</cfif>

		<cfif ListFind(variables.stateList, form.state) lte 0>
			<cfset ArrayAppend(variables.newErrorSet, "Please select State") />
		</cfif>

		<cfif Trim(form.zipCode) eq "">
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Zip Code") />
		</cfif>

		<cfif not IsValid("email", variables.stringHelperObj.StripHtml(Trim(form.personalEmail)))>
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Email Address") />
		</cfif>

		<cfif not IsValid("telephone", variables.stringHelperObj.StripHtml(Trim(form.cellularPhone)))>
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Cellular Phone in format 111-222-3333 or (111)222-3333") />
		</cfif>

		<cfif not IsValid("telephone", variables.stringHelperObj.StripHtml(Trim(form.otherPhone)))>
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Other Phone in format 111-222-3333 or (111)222-3333") />
		</cfif>

		<cfif Len(Trim(form.comments)) gt 255>
			<cfset ArrayAppend(variables.newErrorSet, "Please enter Comments of 255 or fewer characters or leave blank") />
		</cfif>

		<cfif ArrayLen(variables.newErrorSet) eq 0>
			
			<cfobject name="variables.stringHelperObj" component="cds_string_helper" />

			<cfinvoke component="#variables.standByObj#" method="addContactInfoToStandByList">
				<cfif sbl_type eq "public">
					<cfinvokeargument name="listId" value="#url.e#" />
				<cfelse>
					<cfinvokeargument name="listId" value="#url.sbl#" />
				</cfif>
				<cfinvokeargument name="comments" value="#variables.stringHelperObj.StripHtml(Trim(form.comments))#" />
				<cfinvokeargument name="lastName" value="#variables.stringHelperObj.StripHtml(Trim(form.lastName))#" />
				<cfinvokeargument name="firstName" value="#variables.stringHelperObj.StripHtml(Trim(form.firstName))#" />			
				<cfinvokeargument name="streetAddress1" value="#variables.stringHelperObj.StripHtml(Trim(form.street1))#" />
				<cfinvokeargument name="streetAddress2" value="#variables.stringHelperObj.StripHtml(Trim(form.street2))#" />
				<cfinvokeargument name="city" value="#variables.stringHelperObj.StripHtml(Trim(form.city))#" />
				<cfinvokeargument name="state" value="#variables.stringHelperObj.StripHtml(Trim(form.state))#" />
				<cfinvokeargument name="zipCode" value="#variables.stringHelperObj.StripHtml(Trim(form.zipCode))#" />
				<cfinvokeargument name="personalEmail" value="#variables.stringHelperObj.StripHtml(Trim(form.personalEmail))#" />
				<cfinvokeargument name="cellularPhone" value="#variables.stringHelperObj.StripHtml(Trim(form.cellularPhone))#" />
				<cfinvokeargument name="otherPhone" value="#variables.stringHelperObj.StripHtml(Trim(form.otherPhone))#" />
				<cfif sbl_type eq "public">
					<cfinvokeargument name="listStatus" value="public" />
				<cfelse>
					<cfinvokeargument name="listStatus" value="private" />
				</cfif>			
			</cfinvoke>

			<cfset variables.completed=true />

		</cfif>

	</cfif>
		
	<cfoutput>
		
		<!--- 	
		Registration is complete/successful
		--->
		<cfif variables.completed eq true>
			<h3>You have been added to 
			<cfif sbl_type eq "public"> the standby list.<cfelse> Locked and Loaded.</cfif></h3>
													
		
		<!--- 	
		Registration is NOT complete
		--->					
		<cfelse>

			<h1>Standby Lists</h1>
					
			<h2><a href="assets/2ndTIER_TAB_ABOUTPHOTO413.jpg"><img class="aligncenter size-full wp-image-1669" title="2ndTIER_TAB_ABOUTPHOTO413" alt="" src="assets/2ndTIER_TAB_ABOUTPHOTO413.jpg" width="609" height="272" /></a></h2>		
			
			<cfif sbl_type eq "public">	
				<p class="bodycopyblack"><strong>Standby List for #HtmlEditFormat(variables.listData.List_Name)#</strong>		</p>
				<p>
					<cfif Trim(variables.listData.Comments) neq ""><br />#HtmlEditFormat(variables.listData.Comments)#</cfif>
				</p>
			</cfif>			
		
		
		
		
			<cfif sbl_type neq "public">	
				<p class="bodycopyblack">&nbsp;</p>
				There are two ways to join the Availability List. Please <strong>choose one</strong>:
				<ol>
					<li><strong>If you ALREADY HAVE a Wardlaw email address</strong>, one where the domain is _________@wardlawclaims.com, you enter it in the section labeled 'Join Availability List by using your Wardlaw email address'.</li>
					<p class="header2" style="color:##000000">OR</p>
					<li><strong>If you DO NOT HAVE a Wardlaw email address </strong>please provide your contact information in the section labeled 'Join Availability List by submitting your contact information'</li>
				</ol>
				<p>&nbsp;</p>
				<p>*By registering for the Availability List, you are under no obligation to work for Wardlaw Claims Service nor does Wardlaw warranty any offer of work.  However, in the event of a hurricane, Wardlaw will continue to communicate with Availability List registered adjusters about the work opportunities we have available.</p>
			<cfelse>
				<p class="bodycopyblack">&nbsp;</p>
				There are two methods for joining the standby list.
				<ol>
					<li>If you have a Wardlaw email address, one where the domain is @wardlawclaims.com, you enter it in the<br /> section labeled 'Join standby list by using your Wardlaw email address'.</li>
					<li>If you do not have a Wardlaw email address please provide your contact information in the section labeled<br /> 'Join standby list by submitting your contact information'</li>
				</ol>
				<p>&nbsp;</p>
			</cfif>							
		
			<cfif sbl_type eq "public">
				<cfset myaction = Evaluate(DE("stand-by-list-register.cfm?e=#UrlEncodedFormat(url.e)#"))>
			<cfelse>
				<cfset myaction = Evaluate(DE("stand-by-list-register.cfm?sbl=#UrlEncodedFormat(url.sbl)#"))>
			</cfif>

		
			<p><span style="color:red;">*</span> = Required Fields</p>

			<!--- form for wardlaw email --->
			<cfform name="wardlawFrm" action="#myaction#" method="post">
				<div style="border:1px solid ##000000; padding: 2%; padding-bottom: 5px; margin-bottom: 10px;">
			
				<cfif ArrayLen(variables.wardlawErrorSet) gt 0>				
					<cfinvoke component="validation_helper" method="DisplayInputErrorMessages">
						<cfinvokeargument name="errorSet" value="#variables.wardlawErrorSet#" />
					</cfinvoke>				
				</cfif>		
		
		
				<cfif sbl_type eq "public">
					<p><span style="font-weight: bold">Join standby list by using your Wardlaw email address</span></p><br />
				<cfelse>
					<p><span style="font-weight: bold">Join Availability List by using your Wardlaw email address</span></p><br />			
				</cfif>	
			
				<span style="color:##FF3300;">*</span>Wardlaw Email Address<p align="left"></p>
				<cfinput name="wcsEmail" type="text" message="Please enter your Wardlaw email address" maxlength="100" size="18" required="no" validate="email" value="#Iif(not IsDefined('form.newSbmt') and IsValid('email', url.em), DE(url.em), DE('') )#" />
					
				<p align="left">Comments </p>
				<cftextarea name="comments" maxlength="255" width="80" height="20" required="no" validate="maxlength" message="Please enter Comments of 255 or fewer characters or leave blank"></cftextarea>
				<p align="left"><cfinput type="submit" name="wardlawSbmt" value="Submit" validate="submitonce" /></p>
		
		
				</div>
			</cfform>
		
			
			<cfif sbl_type eq "public">
				<cfset myaction = Evaluate(DE("stand-by-list-register.cfm?e=#UrlEncodedFormat(url.e)#"))>
			<cfelse>
				<cfset myaction = Evaluate(DE("stand-by-list-register.cfm?sbl=#UrlEncodedFormat(url.sbl)#"))>
			</cfif>
							
			<!--- form for new registrant --->
			<cfform name="newFrm" action="#myaction#" method="post">
				<div style="border:1px solid ##000000; padding: 2%;">															
												
					<cfif sbl_type eq "public">
						<span style="font-weight: bold">Join standby list by submitting your contact information</span>
					<cfelse>
						<span style="font-weight: bold;font-size:14px">Join Availability List by submitting your contact information</span>
					</cfif>
														
					<cfif ArrayLen(variables.newErrorSet) gt 0>
						<cfinvoke component="wardlawclaims_inc.validation_helper" method="DisplayInputErrorMessages"><cfinvokeargument name="errorSet" value="#variables.newErrorSet#" /></cfinvoke>			
					</cfif>
					<BR/><BR/>										
					<span style="color:##FF3300;">*</span>First Name<BR/><BR/>
					<cfinput type="text" name="firstName" maxlength="20" size="20" required="yes" message="Please enter your First Name" validate="noblanks" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Last Name<BR/><BR/>
					<cfinput type="text" name="lastName" maxlength="20" size="20" required="yes" message="Please enter your Last Name" validate="noblanks" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Street Address<BR/><BR/>
					<cfinput type="text" name="street1" maxlength="50" size="50" required="yes" message="Please enter your Street Address" validate="noblanks" />				<BR/>
					<cfinput type="text" name="street2" maxlength="50" size="50" required="no" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>City<BR/><BR/>
					<cfinput type="text" name="city" maxlength="35" size="35" required="yes" message="Please enter City" validate="noblanks" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>State<BR/><BR/>
					<select id="state" name="state">
						<option value="AL">Alabama</option>
						<option value="AK">Alaska</option>
						<option value="AZ">Arizona</option>
						<option value="AR">Arkansas</option>
						<option value="CA">California</option>
						<option value="CO">Colorado</option>
						<option value="CT">Connecticut</option>
						<option value="DE">Delaware</option>
						<option value="FL">Florida</option>
						<option value="GA">Georgia</option>
						<option value="HI">Hawaii</option>
						<option value="ID">Idaho</option>
						<option value="IL">Illinois</option>
						<option value="IN">Indiana</option>
						<option value="IA">Iowa</option>
						<option value="KS">Kansas</option>
						<option value="KY">Kentucky</option>
						<option value="LA">Louisiana</option>
						<option value="ME">Maine</option>
						<option value="MD">Maryland</option>
						<option value="MA">Massachusetts</option>
						<option value="MI">Michigan</option>
						<option value="MN">Minnesota</option>
						<option value="MS">Mississippi</option>
						<option value="MO">Missouri</option>
						<option value="MT">Montana</option>
						<option value="NE">Nebraska</option>
						<option value="NV">Nevada</option>
						<option value="NH">New Hampshire</option>
						<option value="NJ">New Jersey</option>
						<option value="NM">New Mexico</option>
						<option value="NY">New York</option>
						<option value="NC">North Carolina</option>
						<option value="ND">North Dakota</option>
						<option value="OH">Ohio</option>
						<option value="OK">Oklahoma</option>
						<option value="OR">Oregon</option>
						<option value="PA">Pennsyvania</option>
						<option value="RI">Rhode Island</option>
						<option value="SC">South Carolina</option>
						<option value="SD">South Dakota</option>
						<option value="TN">Tennessee</option>
						<option selected="selected" value="TX">Texas</option>
						<option value="UT">Utah</option>
						<option value="VT">Vermont</option>
						<option value="VA">Virginia</option>
						<option value="WA">Washington</option>
						<option value="DC">Washington DC</option>
						<option value="WV">West Virginia</option>
						<option value="WI">Wisconsin</option>
						<option value="WY">Wyoming</option>
					</select> 										
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Zip Code<BR/><BR/>
					<cfinput type="text" name="zipCode" maxlength="10" size="10" required="yes" validate="noblanks" message="Please enter Zip Code" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Email Address<BR/><BR/>
					<cfinput type="text" name="personalEmail" maxlength="100" size="50" required="yes" message="Please enter your Email Address" validate="email" />
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Cellular Phone<BR/><BR/>
					<cfinput type="text" name="cellularPhone" maxlength="20" size="20" required="yes" message="Please enter your Cellular Phone in format 111-222-3333 or (111)222-3333" validate="telephone" /> <span style="font-size: smaller;">Use format 111-222-3333 or (111)222-3333</span>
					<BR/><BR/>
					<span style="color:##FF3300;">*</span>Other Phone<BR/><BR/>
					<cfinput type="text" name="otherPhone" maxlength="20" size="20" required="yes" message="Please enter your Other Phone in format 111-222-3333 or (111)222-3333" validate="telephone" /> <span style="font-size: smaller;">Use format 111-222-3333 or (111)222-3333</span>
					<BR/><BR/>
					Comments<BR/><BR/>
					<cftextarea name="comments" maxlength="255" cols="50" rows="6" required="no" validate="maxlength" message="Please enter Comments of 255 or fewer characters or leave blank"></cftextarea>
					<BR/><BR/>
					<cfinput type="submit" name="newSbmt" value="Submit" validate="submitonce" />
					
					
					
				</div>
			</cfform>
		
		
		
		
		
		
		
		</cfif>	 <!--- end main condition for registration completed --->		
	</cfoutput>
	
</div>
			
			
			
<!-- THIS IS THE PART YOU SWAP OUT - END -->
</div>

<cfmodule template="/footer.cfm">	