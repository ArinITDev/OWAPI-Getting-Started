$moduleRoot = 'C:\Repos\PWSh-OWAPI-Integration\modules'
$env:PSModulePath = "$moduleRoot;$env:PSModulePath"

# Load modules
Import-Module C:\Repos\PWSh-OWAPI-Integration\modules\Arin.Logging -Force
Import-Module C:\Repos\PWSh-OWAPI-Integration\modules\Arin.Security.DPAPI -Force
Import-Module C:\Repos\PWSh-OWAPI-Integration\modules\Arin.Integration.OWAPI -Force

# Get bearer token
$Cred64 = Read-OWUserCredFile -UsrOWID 6
$BearerToken = Get-OWBearerToken -Cred64 $Cred64
Clear-Host

# API authentication headers.
# $BearerToken must already contain a valid OrderWise bearer token.
$Headers = @{
    Authorization = "Bearer $BearerToken"
    Accept        = "application/json"
}

# The OrderWise API Export Definition that we want to execute.
# This ID corresponds to the specific Export Definition in OrderWise that we want to execute
# defined in eCommerce > API Export Definitions as the [Export definition ID]
$APIExpDefID = 99

$Uri = "https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/$APIExpDefID"

# ------------------------------------------------------------
# Values that we want to pass to the Export Definition
# ------------------------------------------------------------
$cd_id = 3115

# ------------------------------------------------------------
# Build the API parameter array.
#
# The parameter names must match the parameters defined in the
# OrderWise Export Definition.
# ------------------------------------------------------------
$Parameters = @(
    @{
        name  = "@cd_id"
        value = $cd_id
    }
)

# ------------------------------------------------------------
# Convert the PowerShell objects into JSON.
#
# -Compress keeps the JSON on a single line.
# ------------------------------------------------------------
# -InputObject (not the pipeline) keeps a single-item array as a JSON array.
$Body = ConvertTo-Json -InputObject @($Parameters) -Depth 5 -Compress

# ------------------------------------------------------------
# Display what we are about to send.
# Useful when developing or troubleshooting the integration.
# ------------------------------------------------------------
Write-Host "POST $Uri"
Write-Host $Body

# ------------------------------------------------------------
# Send the request to OrderWise.
# ------------------------------------------------------------
$Resp = Invoke-WebRequest `
    -Method POST `
    -Uri $Uri `
    -Headers $Headers `
    -ContentType "application/json" `
    -Body $Body `
    -TimeoutSec 120 `
    -ErrorAction Stop `
    -UseBasicParsing

# ------------------------------------------------------------
<# SQL executed on host

SELECT
 	  cd_id
 	, cd_ow_account
 	, cd_statement_name
 	, ca_n_1
 	, ca_n_2
 	, ca_n_3
 	, ca_n_4
FROM customer_detail LEFT JOIN customer_analysis ON ca_customer_id = cd_id
WHERE cd_id = @cd_id
#>
# ------------------------------------------------------------

# ------------------------------------------------------------
# OrderWise returns JSON.
# Convert the JSON response into PowerShell objects.
# ------------------------------------------------------------
$data = $Resp.Content | ConvertFrom-Json -ErrorAction Stop

# ------------------------------------------------------------
# Display the results returned by the Export Definition.
# ------------------------------------------------------------
$data | Format-Table `
    cd_id,
    cd_ow_account,
    cd_statement_name,
    @{L='ca_n_1'; E={'{0:F4}' -f $_.ca_n_1}},
    @{L='ca_n_2'; E={'{0:F4}' -f $_.ca_n_2}},
    @{L='ca_n_3'; E={'{0:F4}' -f $_.ca_n_3}},
    @{L='ca_n_4'; E={'{0:F4}' -f $_.ca_n_4}} `
    -AutoSize |
    Out-Host


<# Program Output
POST https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/99
[{"value":3115,"name":"@cd_id"}]

cd_id cd_ow_account cd_statement_name ca_n_1 ca_n_2 ca_n_3  ca_n_4
----- ------------- ----------------- ------ ------ ------  ------
 3115 TEST          Used for testing  8.9444 1.1930 13.2475 1.3396

#>