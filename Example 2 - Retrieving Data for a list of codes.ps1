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
$currency_codes = 'CNY,EUR,SEK,USD'

# ------------------------------------------------------------
# Build the API parameter array.
#
# The parameter names must match the parameters defined in the
# OrderWise Export Definition.
# ------------------------------------------------------------
$Parameters = @(
    @{
        name  = "@currency_codes"
        value = $currency_codes
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
# SQL executed on host
#
# SELECT
#       c.c_currency_code
#     , c_exchange_rate
#     , c_currency_symbol
#     , c_last_amended_datetime
#     , ud_username
# FROM dbo.currency AS c
#     INNER JOIN user_detail ON ud_id = c_last_amended_by_user_id
# WHERE c.c_currency_code IN (
#     SELECT LTRIM(RTRIM(value))
#     FROM STRING_SPLIT(@currency_codes, ',')
# );
# ------------------------------------------------------------


# ------------------------------------------------------------
# OrderWise returns JSON.
# Convert the JSON response into PowerShell objects.
# ------------------------------------------------------------
$data = $Resp.Content | ConvertFrom-Json -ErrorAction Stop

# ------------------------------------------------------------
# Display the results returned by the Export Definition.
# ------------------------------------------------------------
$data | Format-Table -AutoSize

Write-Host

$formattedData = $data | ForEach-Object {

    # [ordered] - preserves the column order from the original $data
    $newObject = [ordered]@{}

    foreach ($p in $_.PSObject.Properties) {

        if ($p.Name -eq 'c_exchange_rate') {
            $newObject[$p.Name] = '{0:F4}' -f $p.Value
        }
        else {
            $newObject[$p.Name] = $p.Value
        }
    }

    [PSCustomObject]$newObject
}

$formattedData | Format-Table -AutoSize

<# Program Output
POST https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/96
[{"value":"CNY,EUR,SEK,USD","name":"@currency_codes"}]

c_currency_code c_exchange_rate c_currency_symbol c_last_amended_datetime ud_username
--------------- --------------- ----------------- ----------------------- -----------
EUR                        1.19 €                 02/11/2026 08:23:52     Clark Robertson
USD                        1.34 $                 02/11/2026 08:24:31     Clark Robertson
SEK                       13.25 kr                02/11/2026 08:24:12     Clark Robertson
CNY                        8.94 ¥                 02/11/2026 08:23:34     Clark Robertson



c_currency_code c_exchange_rate c_currency_symbol c_last_amended_datetime ud_username
--------------- --------------- ----------------- ----------------------- -----------
EUR             1.1930          €                 02/11/2026 08:23:52     Clark Robertson
USD             1.3396          $                 02/11/2026 08:24:31     Clark Robertson
SEK             13.2475         kr                02/11/2026 08:24:12     Clark Robertson
CNY             8.9444          ¥                 02/11/2026 08:23:34     Clark Robertson

#>