# Base folder: %LOCALAPPDATA%\Temp\Arinsdale
$baseDir = Join-Path $env:LOCALAPPDATA 'Temp\Arinsdale'

# Create base folder if it doesn't exist
if (-not (Test-Path -LiteralPath $baseDir)) {
    Write-Verbose "Creating base folder: $baseDir"
    New-Item -Path $baseDir -ItemType Directory -Force | Out-Null
}

$year_month  = Get-Date -Format "yyyy-MM"

# Then build the XML file path under it using the date
$xmlFile = Join-Path $baseDir "exrates-monthly-$year_month.xml"
#$outCsv  = "C:\Temp\hmrc_fx_filtered.csv"

$wanted = @("CNY","EUR","SEK","USD")
# ----------------------------

# Download XML
Invoke-WebRequest -Uri $url -OutFile $xmlFile -UseBasicParsing

# Load XML
[xml]$xml = Get-Content $xmlFile
Write-Verbose ("Loaded XML file: {0}" -f $xmlFile)

# Extract required currencies

$rates = $xml.exchangeRateMonthList.exchangeRate |
Where-Object { $wanted -contains $_.currencyCode } |
Select-Object `
    countryName,
    currencyName,
    currencyCode,
    @{n="units_per_gbp";e={[decimal]$_.rateNew}},
    @{n="period";e={$xml.exchangeRateMonthList.Period}}

# Create variables for each currency code with their corresponding values
# Changes to $wanted array will automatically reflect in the variables created below
foreach ($rate in $rates) {
    Set-Variable -Name $rate.currencyCode -Value $rate.units_per_gbp
}

<#

$currencyCodes = ($rates | ForEach-Object { $_.currencyCode }) -join ','

$currencyValues = ($rates | ForEach-Object {
    $_.units_per_gbp.ToString([System.Globalization.CultureInfo]::InvariantCulture)
}) -join ','

Write-Host "Currency codes: $currencyCodes"
Write-Host "Units per GBP:  $currencyValues"


$ratesFormatted = $rates | Select-Object `
    @{Name = 'Country';        Expression = {$_.countryName}},
    @{Name = 'Currency';       Expression = {$_.currencyName}},
    @{Name = 'Code';           Expression = {$_.currencyCode}},
    @{Name = 'Units per GBP';  Expression = {$_.units_per_gbp}},
    @{Name = 'Period';         Expression = {$_.period}}

$ratesFormatted | Format-Table -AutoSize
#>