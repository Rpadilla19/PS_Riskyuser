#necessary modules needed to run the scripts
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns
Import-Module Microsoft.Graph.Reports

#the following block allows user to connect to mg-graph via application in entra
----------------------------------------------------------------------------------------------------------------------------------------
$ApplicationId = <Application ID>
$SecuredPassword = <Password>
$tenantID = <Tenant ID>

$SecuredPasswordPassword = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force

$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPasswordPassword

Connect-MgGraph -ClientSecretCredential $ClientSecretCredential -TenantId $tenantID -NoWelcome

$Date = Get-Date -format "yyyy_MM_dd"

----------------------------------------------------------------------------------------------------------------------------------------

#titles and creates csv files 
$RiskyUsers = "Risky_users" + $Date + ".csv"
$Riskysignins = "Risky_Users_signins" + $Date + ".csv"

#pulls risky users with a high risk level and exports to csv
get-mgriskyuser -All -filter "RiskLevel eq 'High' " | Where-Object { $_.RiskLastUpdatedDateTime -ge $UserDate } | Select-Object UserPrincipalName, studentId, UserDisplayName, RiskLastUpdatedDateTime, RiskLevel, RiskState, Id | Export-Csv -path $RiskyUsers -NoTypeInformation

#puts the risky users into variable
$highRiskUsers = get-mgriskyuser -All -filter "RiskLevel eq 'High' " | Where-Object { $_.RiskLastUpdatedDateTime -ge $UserDate }

#prints starting date for User 
Write-Output $TodayDate
write-output $UserDate
write-output $startDate

#empty arrays for UserprincipalName and SignInEvents
$userNames = @()
$data = @()

#goes through each name in $highriskUser and stores it in $userNames
foreach ($user in $highRiskUsers) {
    $userNames += $user.UserPrincipalName
}


#starting date for Users and Signin events
$UserDate = (Get-Date).AddDays(-10).tostring("dd/MM/yyyy")
$TodayDate = Get-Date -format "yyyy_MM_dd"
$startDate = (Get-Date).Addmonths(-1).ToString("dd/MM/yyyy")

#creates output (userlog) txt file and adds run time date 
$output_file_path = "Risky_userlog" + $TodayDate + ".txt"

#puts date in the first line of the output file
Add-content -path $output_file_path -value $TodayDate



$userNames | ForEach-Object {

    #grabs the users sigin events from $startDate to todays date
    $signInEvents = Get-MgAuditLogSignIn -Filter "UserPrincipalName eq '$_' " | Where-Object { $_.CreatedDateTime -ge $startDate }

    #if a signin event is found than it adds to userlog.txt w/ a count of sign ins. If not than it reports none found
    if ($signInEvents) {
        add-content -Path $output_file_path -value "`n User: $_ - Found $($signInEvents.Count) sign-in events"
        $data += write-output "User: $_ " $signInEvents
    } else {
        add-content -Path $output_file_path -value "`n User: $_ - no sign-in events found"
    }
}

#adds wanted objects
$datavalue = $data | Select-Object UserPrincipalName, Appdisplayname, ConditionalAccessStatus, IPAddress, CreatedDateTime

#Using $RiskyUsers csv file to grab user UPNS
$UPNS = Import-Csv -path $RiskyUsers

#creates array to store objects in
$results = @()

foreach ($user in $UPNS){

    $userPrincipalName = $user.UserPrincipalName

    $userDetails = Get-mgriskyuser -filter "UserPrincipalName eq '$userPrincipalName' " | Select-Object UserPrincipalName, UserDisplayName, RiskLastUpdatedDateTime, RiskLevel, RiskState, Id

    #grabs ID and removes 'CN' from CN=<studenID>
    $onpremisesDN = (Get-MgUser -UserId $userPrincipalName -Property "onPremisesDistinguishedName").onPremisesDistinguishedName 

    $cnValue = ($onpremisesDN -split ',') | Where-Object { $_ -like "CN=*" } | ForEach-Object { $_ -replace 'CN=', '' }
    
    #headers are created on the left side and wanted information is on the right side.
    $result = [PSCustomObject]@{ 
        UserPrincipalName = $userDetails.UserPrincipalName
        Idnumber = $cnValue
        UserDisplayName = $userDetails.UserDisplayName
        RiskLastUpdatedDateTime = $userDetails.RiskLastUpdatedDateTime
        RiskLevel = $userDetails.RiskLevel
        RiskState = $userDetails.RiskState
        Id = $userDetails.Id
    }

    $results += $result

}

#exports headers and information in to $Riskyusers file
$results | Export-Csv -Path $RiskyUsers -NoTypeInformation

#exports sign in logs in to $Riskysignins file
$datavalue | Export-Csv -path $Riskysignins -NoTypeInformation


