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
<# SQL executed on host

SELECT 
     @CNY AS CNY
   , @EUR AS EUR
   , @SEK AS SEK
   , @USD AS USD
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
    @{L='CNY'; E={'{0:F4}' -f $_.CNY}},
    @{L='EUR'; E={'{0:F4}' -f $_.EUR}},
    @{L='SEK'; E={'{0:F4}' -f $_.SEK}},
    @{L='USD'; E={'{0:F4}' -f $_.USD}} |
    Out-Host

# ------------------------------------------------------------
# One of the main benefits of ConvertFrom-Json is that returned
# JSON fields become PowerShell properties.
# ------------------------------------------------------------
Write-Host "Yuan rate: $($data.CNY)"
Write-Host "Euro rate: $($data.EUR)"
Write-Host "Swedish Krona rate: $($data.SEK)"
Write-Host "US Dollar rate: $($data.USD)"
Write-Host

<# Program Output
POST https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/96
[{"value":8.9444,"name":"@CNY"},{"value":1.193,"name":"@EUR"},{"value":13.2475,"name":"@SEK"},{"value":1.3396,"name":"@USD"}]

CNY    EUR    SEK     USD
---    ---    ---     ---
8.9444 1.1930 13.2475 1.3396

Yuan rate: 8.9444
Euro rate: 1.193
Swedish Krona rate: 13.2475
US Dollar rate: 1.3396

#>