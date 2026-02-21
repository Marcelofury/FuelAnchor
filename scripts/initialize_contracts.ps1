#!/usr/bin/env pwsh
# FuelAnchor Contract Initialization Script
# Initializes deployed contracts with admin and default settings

param(
    [Parameter(Mandatory=$false)]
    [string]$AdminKey = "admin",
    
    [Parameter(Mandatory=$false)]
    [string]$Network = "testnet"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 FuelAnchor Contract Initialization" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Load contract IDs from environment or CONTRACT_IDS.txt
if (-not (Test-Path "CONTRACT_IDS.txt")) {
    Write-Host "❌ CONTRACT_IDS.txt not found! Run deploy_contracts.ps1 first." -ForegroundColor Red
    exit 1
}

$contractIds = Get-Content "CONTRACT_IDS.txt" | Where-Object { $_ -match "=" }
$fuelTokenId = ($contractIds | Where-Object { $_ -match "FUEL_TOKEN_CONTRACT_ID" }).Split("=")[1]
$voucherId = ($contractIds | Where-Object { $_ -match "VOUCHER_REDEMPTION_CONTRACT_ID" }).Split("=")[1]
$creditScoreId = ($contractIds | Where-Object { $_ -match "CREDIT_SCORE_CONTRACT_ID" }).Split("=")[1]
$geofencingId = ($contractIds | Where-Object { $_ -match "GEOFENCING_CONTRACT_ID" }).Split("=")[1]

$adminAddress = stellar keys address $AdminKey

Write-Host "📋 Contract IDs loaded:" -ForegroundColor Green
Write-Host "  Fuel Token:         $fuelTokenId" -ForegroundColor Gray
Write-Host "  Voucher Redemption: $voucherId" -ForegroundColor Gray
Write-Host "  Credit Score:       $creditScoreId" -ForegroundColor Gray
Write-Host "  Geofencing:         $geofencingId" -ForegroundColor Gray
Write-Host ""
Write-Host "👤 Admin Address: $adminAddress" -ForegroundColor Green
Write-Host ""

# Initialize Fuel Token Contract
Write-Host "🪙 Initializing Fuel Token Contract..." -ForegroundColor Blue
try {
    stellar contract invoke `
        --id $fuelTokenId `
        --source $AdminKey `
        --network $Network `
        -- initialize `
        --admin $adminAddress `
        --decimal 7 `
        --name "FuelAnchor Token" `
        --symbol "FUEL"
    
    Write-Host "✅ Fuel Token initialized" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Fuel Token may already be initialized" -ForegroundColor Yellow
}

Write-Host ""

# Initialize Credit Score Contract
Write-Host "📊 Initializing Credit Score Contract..." -ForegroundColor Blue
try {
    stellar contract invoke `
        --id $creditScoreId `
        --source $AdminKey `
        --network $Network `
        -- initialize `
        --admin $adminAddress
    
    Write-Host "✅ Credit Score initialized" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Credit Score may already be initialized" -ForegroundColor Yellow
}

Write-Host ""

# Initialize Geofencing Contract
Write-Host "📍 Initializing Geofencing Contract..." -ForegroundColor Blue
try {
    stellar contract invoke `
        --id $geofencingId `
        --source $AdminKey `
        --network $Network `
        -- initialize `
        --admin $adminAddress `
        --max_distance 100
    
    Write-Host "✅ Geofencing initialized (max distance: 100m)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Geofencing may already be initialized" -ForegroundColor Yellow
}

Write-Host ""

# Initialize Voucher Redemption Contract
Write-Host "🎟️  Initializing Voucher Redemption Contract..." -ForegroundColor Blue
try {
    stellar contract invoke `
        --id $voucherId `
        --source $AdminKey `
        --network $Network `
        -- initialize `
        --admin $adminAddress `
        --fuel_token_id $fuelTokenId `
        --credit_score_id $creditScoreId `
        --geofencing_id $geofencingId
    
    Write-Host "✅ Voucher Redemption initialized" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Voucher Redemption may already be initialized" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Contract initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Mint initial FUEL tokens for testing"
Write-Host "2. Set up merchant and fleet operator accounts"
Write-Host "3. Configure geofencing zones for stations"
Write-Host ""
Write-Host "Run './scripts/mint_tokens.ps1' to mint test tokens" -ForegroundColor Cyan
