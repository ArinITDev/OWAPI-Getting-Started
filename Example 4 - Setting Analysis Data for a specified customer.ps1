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
$APIExpDefID = 100

$Uri = "https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/$APIExpDefID"

# ------------------------------------------------------------
# Values that we want to pass to the Export Definition
# ------------------------------------------------------------
$cd_id = 3115
$CNY = 8.9444
$EUR = 1.1930
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
        name  = "@cd_id"
        value = $cd_id
    },
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

-- Create a row in the customer_analysis table if it doesn't already exist
IF NOT EXISTS (
    SELECT 1
    FROM customer_analysis WITH (UPDLOCK, HOLDLOCK)
    WHERE ca_customer_id = @cd_id
)
BEGIN
    INSERT INTO customer_analysis (ca_customer_id)
    VALUES (@cd_id);
END

UPDATE customer_analysis
SET   ca_n_1 = @CNY
    , ca_n_2 = @EUR
    , ca_n_3 = @SEK
    , ca_n_4 = @USD
WHERE ca_customer_id = @cd_id

-- Return the new values back to the request
SELECT
    cd_id,
    ca_id,
    ca_customer_id,
    ca_n_1, ca_n_2, ca_n_3, ca_n_4
FROM customer_detail 
LEFT JOIN customer_analysis ON ca_customer_id = cd_id
WHERE cd_id = @cd_id;
#>
# ------------------------------------------------------------


# ------------------------------------------------------------
# OrderWise returns JSON.
# Convert the JSON response into PowerShell objects.
# ------------------------------------------------------------
$data = $Resp.Content | ConvertFrom-Json -ErrorAction Stop

# ------------------------------------------------------------
# Display the results returned by the Export Definition.
# NB For currencies we want to display with 4 decimal places, ie use the FormatString 'F4' in the table columns.
# ------------------------------------------------------------
$data | Format-Table cd_id, ca_id, ca_customer_id,
    @{ Label = 'ca_n_1'; Expression = { $_.ca_n_1 }; FormatString = 'F4' },
    @{ Label = 'ca_n_2'; Expression = { $_.ca_n_2 }; FormatString = 'F4' },
    @{ Label = 'ca_n_3'; Expression = { $_.ca_n_3 }; FormatString = 'F4' },
    @{ Label = 'ca_n_4'; Expression = { $_.ca_n_4 }; FormatString = 'F4' } -AutoSize

Write-Host

<# Program Output
POST https://arinsdale.orderwisecloud.com/OWAPI/system/export-definition/100
[{"value":3115,"name":"@cd_id"},{"value":8.9444,"name":"@CNY"},{"value":1.193,"name":"@EUR"},{"value":13.2475,"name":"@SEK"},{"value":1.3396,"name":"@USD"}]
                                                                                                                        
cd_id ca_id ca_customer_id ca_n_1 ca_n_2  ca_n_3 ca_n_4
----- ----- -------------- ------ ------  ------ ------
 3115  5286           3115 8.9444 1.1930 13.2475 1.3396

#>