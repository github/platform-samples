#Requires -version 7

<#
.SYNOPSIS
Batch invite members to an organization

.DESCRIPTION
This script runs a batch organization invitation process for a given list of GitHub Enterprise
Cloud consumed licenses.

The input is a CSV file with a column named "Handle or email", such as can be exported from the
Enterprise settings > Enterprise licensing page. Users with appropriate permissions can export
the CSV file, edit it in their favorite spreadsheet to select emails to invite, then use this
script to invite them to an org.

.PARAMETER LicensesFile
The path of the consumed licenses CSV.

.PARAMETER Organization
The name of the organization to invite members to.

.PARAMETER PAT
The personal access token. It must have "admin:org" scope to be authorized for the operation.

.EXAMPLE
.\invite_members_to_org.ps1 -LicensesFile .\consumed_licenses.csv -Organization my-organization -PAT xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#>

param (
  [string] [Parameter(Mandatory=$true)] $LicensesFile,
  [string] [Parameter(Mandatory=$true)] $Organization,
  [string] [Parameter(Mandatory=$true)] $PAT
)

Import-Csv $LicensesFile | ForEach-Object {
    Write-Host "---------------------------------------------"

    $Body = @{}
    if ($_."Handle or email" -Match "@") {
        Write-Host "Inviting email $($_."Handle or email")..."
        $Body.email = $_."Handle or email"
    } else {
        Write-Host "Inviting handle $($_."Handle or email")..."
        $HandleIdRequest = Invoke-RestMethod -SkipHttpErrorCheck -Uri "https://api.github.com/users/$($_."Handle or email")"
        if ($null -ne $HandleIdRequest.id) {
            Write-Host "> Handle id is $($HandleIdRequest.id)" -ForegroundColor 'green'
        } else {
            Write-Host "> Handle id not found" -ForegroundColor 'red'
        }
        $Body.invitee_id = $HandleIdRequest.id
    }

    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "Authorization" = "token $($PAT)"
    }

    $InvitationRequest = Invoke-RestMethod -StatusCodeVariable "StatusCode" -SkipHttpErrorCheck -Uri "https://api.github.com/orgs/$($Organization)/invitations" -Method Post -Headers $headers -Body ($body | ConvertTo-Json)
    if ($StatusCode -eq 201) {
        Write-Host "> Success!" -ForegroundColor 'green'
    } else {
        Write-Host "> Error!" -ForegroundColor 'red'
        Write-Host "> Status code: $($StatusCode)" -ForegroundColor 'red'
        Write-Host "> $($InvitationRequest | ConvertTo-Json)" -ForegroundColor 'red'
    }
}

Write-Host "---------------------------------------------"
Write-Host "End of file"
