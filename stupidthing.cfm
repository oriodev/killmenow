<cfset userType = "#session.int_EmployeeType#">

<cfquery datasource="#request.datasource#" name="GetEvents">
    -- this grabs all the employees attached to an event and concats their ids into a string
    WITH EmployeeIDs AS (
        SELECT 
            eventEmployees.int_eventID,
            STRING_AGG(employee.int_EmployeeID, ', ') AS employeeIDs,
            STRING_AGG(employee.int_VenueID, ', ') AS employeeVenueIDS
        FROM 
            tbl_eventEmployees AS eventEmployees
        LEFT JOIN 
            tbl_Employee AS employee ON eventEmployees.int_employeeID = employee.int_employeeID
        GROUP BY 
            eventEmployees.int_eventID
    )
    -- back to normal sql-ing
    SELECT DISTINCT
        events.*,
        venue.str_VenueName AS venueName,
        emp.employeeIDs,
        emp.employeeVenueIDS
    FROM 
        tbl_events AS events
    LEFT JOIN 
        EmployeeIDs AS emp ON events.id = emp.int_eventID
    LEFT JOIN
        tbl_Venues AS venue ON events.int_venueID = venue.int_venueID -- get the venue info
    
    -- only return when linked to the right company
    WHERE events.int_companyID = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.int_CompanyID#">
    
    -- if user is venue manager
    <cfif userType EQ 5>
        AND (
            events.int_venueID = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.int_VenueID#"> 
            OR (
                emp.employeeVenueIDS IS NOT NULL 
                AND EXISTS (
                    SELECT 1 
                    FROM STRING_SPLIT(emp.employeeVenueIDS, ', ') AS splitValues
                    WHERE splitValues.value = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.int_VenueID#">
                )
            )
            OR events.int_EventType IN (1)
        )
    </cfif>

    -- if user is employee
    <cfif userType EQ 10>
        AND (
            events.int_venueID = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.int_VenueID#"> 
            -- TODO: EMPLOYEES CAN SEE TYPE 3 LINKED TO THEM

            OR events.int_EventType IN (1)
        )
    </cfif>
</cfquery>