#!/usr/bin/env pwsh
# FuelAnchor Token Minting Script
# Mints FUEL tokens for testing purposes

param(
    [Parameter(Mandatory=$false)]
    [string]$AdminKey = "admin",
    
    [Parameter(Mandatory=$false)]
    [string]$Amount = "10000",
    
    [Parameter(Mandatory=$false)]
    [string]$Recipient = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Network = "testnet"
)

$ErrorActionPreference = "Stop"

Write-Host "🪙 FuelAnchor Token Minting" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Load contract IDs
if (-not (Test-Path "CONTRACT_IDS.txt")) {
    Write-Host "❌ CONTRACT_IDS.txt not found! Run deploy_contracts.ps1 first." -ForegroundColor Red
    exit 1
}

$contractIds = Get-Content "CONTRACT_IDS.txt" | Where-Object { $_ -match "=" }
$fuelTokenId = ($contractIds | Where-Object { $_ -match "FUEL_TOKEN_CONTRACT_ID" }).Split("=")[1]

$adminAddress = stellar keys address $AdminKey

if ($Recipient -eq "") {
    $Recipient = $adminAddress
}

Write-Host "📋 Minting Details:" -ForegroundColor Green
Write-Host "  Token Contract: $fuelTokenId" -ForegroundColor Gray
Write-Host "  Amount:         $Amount FUEL" -ForegroundColor Gray
Write-Host "  Recipient:      $Recipient" -ForegroundColor Gray
Write-Host "  Network:        $Network" -ForegroundColor Gray
Write-Host ""

# Convert amount to smallest unit (7 decimals)
$amountStroops = [int64]$Amount * 10000000

Write-Host "💰 Minting $Amount FUEL tokens..." -ForegroundColor Blue
try {
    stellar contract invoke `
        --id $fuelTokenId `
        --source $AdminKey `
        --network $Network `
        -- mint `
        --to $Recipient `
        --amount $amountStroops
    
    Write-Host "✅ Successfully minted $Amount FUEL tokens to $Recipient" -ForegroundColor Green
    Write-Host ""
    
    # Check balance
    Write-Host "💼 Checking balance..." -ForegroundColor Blue
    $balance = stellar contract invoke `
        --id $fuelTokenId `
        --source $AdminKey `
        --network $Network `
        -- balance `
        --id $Recipient
    
    $balanceFuel = [decimal]$balance / 10000000
    Write-Host "✅ Current balance: $balanceFuel FUEL" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to mint tokens: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Token minting complete!" -ForegroundColor Green
