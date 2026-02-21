#!/usr/bin/env pwsh
# FuelAnchor Contract Monitoring Script
# Monitors contract status and recent transactions

param(
    [Parameter(Mandatory=$false)]
    [string]$Network = "testnet",
    
    [Parameter(Mandatory=$false)]
    [switch]$Watch = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$RefreshSeconds = 30
)

$ErrorActionPreference = "Stop"

function Show-ContractStatus {
    Write-Host "📊 FuelAnchor Contract Status Monitor" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""

    # Load contract IDs
    if (-not (Test-Path "CONTRACT_IDS.txt")) {
        Write-Host "❌ CONTRACT_IDS.txt not found!" -ForegroundColor Red
        return
    }

    $contractIds = Get-Content "CONTRACT_IDS.txt" | Where-Object { $_ -match "=" }
    $fuelTokenId = ($contractIds | Where-Object { $_ -match "FUEL_TOKEN_CONTRACT_ID" }).Split("=")[1]
    $creditScoreId = ($contractIds | Where-Object { $_ -match "CREDIT_SCORE_CONTRACT_ID" }).Split("=")[1]
    $geofencingId = ($contractIds | Where-Object { $_ -match "GEOFENCING_CONTRACT_ID" }).Split("=")[1]

    # Check Fuel Token
    Write-Host "🪙 Fuel Token Contract" -ForegroundColor Yellow
    Write-Host "  ID: $fuelTokenId" -ForegroundColor Gray
    try {
        $name = stellar contract invoke --id $fuelTokenId --network $Network -- name 2>$null
        $symbol = stellar contract invoke --id $fuelTokenId --network $Network -- symbol 2>$null
        $totalSupply = stellar contract invoke --id $fuelTokenId --network $Network -- total_supply 2>$null
        
        if ($totalSupply) {
            $supplyFuel = [decimal]$totalSupply / 10000000
            Write-Host "  Name: $name" -ForegroundColor Green
            Write-Host "  Symbol: $symbol" -ForegroundColor Green
            Write-Host "  Total Supply: $supplyFuel FUEL" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠️  Unable to fetch token data" -ForegroundColor Yellow
    }
    Write-Host ""

    # Check Credit Score Contract
    Write-Host "📊 Credit Score Contract" -ForegroundColor Yellow
    Write-Host "  ID: $creditScoreId" -ForegroundColor Gray
    try {
        $totalUsers = stellar contract invoke --id $creditScoreId --network $Network -- get_total_users 2>$null
        if ($totalUsers) {
            Write-Host "  Total Users: $totalUsers" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠️  Unable to fetch credit score data" -ForegroundColor Yellow
    }
    Write-Host ""

    # Network Status
    Write-Host "🌐 Network Status" -ForegroundColor Yellow
    Write-Host "  Network: $Network" -ForegroundColor Gray
    
    # Try to get latest ledger
    try {
        $horizonUrl = if ($Network -eq "testnet") { 
            "https://horizon-testnet.stellar.org" 
        } else { 
            "https://horizon.stellar.org" 
        }
        
        $response = Invoke-RestMethod -Uri "$horizonUrl/ledgers?order=desc&limit=1" -Method Get -TimeoutSec 5
        $latestLedger = $response._embedded.records[0].sequence
        $ledgerTime = $response._embedded.records[0].closed_at
        
        Write-Host "  Latest Ledger: $latestLedger" -ForegroundColor Green
        Write-Host "  Closed At: $ledgerTime" -ForegroundColor Green
        Write-Host "  ✅ Network is operational" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Unable to connect to Horizon" -ForegroundColor Yellow
    }
    Write-Host ""

    # Contract Endpoints Summary
    Write-Host "📝 Contract Endpoints" -ForegroundColor Yellow
    Write-Host "  Fuel Token:         $fuelTokenId" -ForegroundColor Gray
    Write-Host "  Credit Score:       $creditScoreId" -ForegroundColor Gray
    Write-Host "  Geofencing:         $geofencingId" -ForegroundColor Gray
    Write-Host ""

    if ($Watch) {
        Write-Host "🔄 Refreshing in $RefreshSeconds seconds (Ctrl+C to stop)..." -ForegroundColor Cyan
        Write-Host ""
    }
}

if ($Watch) {
    while ($true) {
        Clear-Host
        Show-ContractStatus
        Start-Sleep -Seconds $RefreshSeconds
    }
} else {
    Show-ContractStatus
}

Write-Host "✅ Monitoring complete" -ForegroundColor Green
