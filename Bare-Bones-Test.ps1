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

# The OrderWise Export Definition that we want to execute.
$APIExpDefID = 96

$Uri = "https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/$APIExpDefID"


# ------------------------------------------------------------
# Values that we want to pass to the Export Definition
# ------------------------------------------------------------

$CNY = 8.9444
$EUR = 1.193
$SEK = 13.2475
$USD = 1.3396


# ------------------------------------------------------------
# Build the API parameter array.
#
# The parameter names must match the parameters defined in the
# OrderWise Export Definition.
# ------------------------------------------------------------

$Parameters = @(
    @{
        name  = "@CNY"
        value = $CNY
    },
    @{
        name  = "@EUR"
        value = $EUR
    },
    @{
        name  = "@SEK"
        value = $SEK
    },
    @{
        name  = "@USD"
        value = $USD
    }
)


# ------------------------------------------------------------
# Convert the PowerShell objects into JSON.
#
# -Compress keeps the JSON on a single line.
# ------------------------------------------------------------

$Body = $Parameters | ConvertTo-Json -Depth 5 -Compress


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
# OrderWise returns JSON.
# Convert the JSON response into PowerShell objects.
# ------------------------------------------------------------

$data = $Resp.Content | ConvertFrom-Json -ErrorAction Stop


# ------------------------------------------------------------
# Display the results returned by the Export Definition.
# ------------------------------------------------------------

$data