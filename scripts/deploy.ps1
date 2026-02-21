# FuelAnchor Smart Contract Deployment Script
# Deploys all Soroban contracts to Stellar Testnet

$ErrorActionPreference = "Stop"

Write-Host "`n=== FuelAnchor Contract Deployment to Testnet ===" -ForegroundColor Cyan
Write-Host ""

# Check if stellar CLI is installed
Write-Host "[1/6] Checking Stellar CLI..." -ForegroundColor Yellow
$stellarCmd = Get-Command stellar -ErrorAction SilentlyContinue
if (-not $stellarCmd) {
    Write-Host "ERROR: Stellar CLI not found!" -ForegroundColor Red
    Write-Host "Install it with: cargo install --locked stellar-cli" -ForegroundColor Yellow
    exit 1
}
Write-Host "SUCCESS: Stellar CLI found (version $(stellar --version | Select-String 'stellar' | ForEach-Object { $_.Line.Split(' ')[1] }))" -ForegroundColor Green
Write-Host ""

# Configure network
Write-Host "[2/6] Configuring Stellar Testnet..." -ForegroundColor Yellow
stellar network add testnet --rpc-url https://soroban-testnet.stellar.org:443 --network-passphrase "Test SDF Network ; September 2015" 2>$null
Write-Host "SUCCESS: Network configured" -ForegroundColor Green
Write-Host ""

# Check if admin keypair exists
Write-Host "[3/6] Checking admin keypair..." -ForegroundColor Yellow
$adminExists = $false
try {
    $null = stellar keys address admin 2>&1
    if ($LASTEXITCODE -eq 0) {
        $adminExists = $true
    }
} catch {
    $adminExists = $false
}

if (-not $adminExists) {
    Write-Host "Generating new admin keypair..." -ForegroundColor Yellow
    stellar keys generate admin --network testnet | Out-Null
    $adminAddress = stellar keys address admin
    Write-Host "SUCCESS: Admin keypair generated" -ForegroundColor Green
    Write-Host "Admin Address: $adminAddress" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANT: You need to fund this account!" -ForegroundColor Red
    Write-Host "Visit: https://laboratory.stellar.org/#account-creator?network=test" -ForegroundColor Cyan
    Write-Host "Paste your address: $adminAddress" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press Enter after funding the account..." -ForegroundColor Yellow
    Read-Host
} else {
    $adminAddress = stellar keys address admin
    Write-Host "SUCCESS: Using existing admin keypair: $adminAddress" -ForegroundColor Green
}
Write-Host ""

# Build all contracts
Write-Host "[4/6] Building all contracts..." -ForegroundColor Yellow
Set-Location contracts

Write-Host "  - Building fuel-token..." -ForegroundColor Gray
Set-Location fuel-token
stellar contract build | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build fuel-token" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "  - Building fuel-lock..." -ForegroundColor Gray
Set-Location fuel-lock
stellar contract build | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build fuel-lock" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "  - Building voucher-redemption..." -ForegroundColor Gray
Set-Location voucher-redemption
stellar contract build | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build voucher-redemption" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "  - Building credit-score..." -ForegroundColor Gray
Set-Location credit-score
stellar contract build | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build credit-score" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "  - Building geofencing..." -ForegroundColor Gray
Set-Location geofencing
stellar contract build | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build geofencing" -ForegroundColor Red
    exit 1
}
Set-Location ..

Write-Host "SUCCESS: All contracts built" -ForegroundColor Green
Write-Host ""

# Create .env file for backend
Write-Host "[5/6] Creating backend .env file..." -ForegroundColor Yellow
$envFile = "..\backend\.env"
@"
# FuelAnchor Backend Environment Configuration
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Server Configuration
PORT=3000
NODE_ENV=development

# Stellar Network Configuration
STELLAR_NETWORK=testnet
STELLAR_HORIZON_URL=https://horizon-testnet.stellar.org
STELLAR_SOROBAN_RPC_URL=https://soroban-testnet.stellar.org:443
STELLAR_NETWORK_PASSPHRASE=Test SDF Network ; September 2015

# Admin Keypair (DO NOT COMMIT TO GIT)
STELLAR_ADMIN_SECRET=GET_THIS_WITH_stellar_keys_show_admin

# CORS Origins
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# Database (Supabase)
DATABASE_URL=

"@ | Out-File -FilePath $envFile -Encoding UTF8
Write-Host "SUCCESS: Created backend/.env" -ForegroundColor Green
Write-Host ""

# Deploy contracts
Write-Host "[6/6] Deploying contracts to testnet..." -ForegroundColor Yellow
Write-Host ""

# Go back to project root for deployment
Set-Location ..

# Update env file path for correct location
$envFile = "backend\.env"

# Deploy fuel-token
Write-Host "  [1/5] Deploying fuel-token..." -ForegroundColor Cyan
$output = stellar contract deploy --wasm "target\wasm32v1-none\release\fuel_token.wasm" --source admin --network testnet 2>&1
$FUEL_TOKEN_ID = ($output | Select-String -Pattern '^C[A-Z0-9]{55}$').Line
if ($FUEL_TOKEN_ID -match '^C[A-Z0-9]{55}$') {
    Write-Host "        SUCCESS: $FUEL_TOKEN_ID" -ForegroundColor Green
    Add-Content -Path $envFile -Value "FUEL_TOKEN_CONTRACT_ID=$FUEL_TOKEN_ID"
} else {
    Write-Host "        ERROR: Failed to deploy fuel-token" -ForegroundColor Red
    Write-Host "        Output: $output" -ForegroundColor Red
    exit 1
}

# Deploy fuel-lock
Write-Host "  [2/5] Deploying fuel-lock..." -ForegroundColor Cyan
$output = stellar contract deploy --wasm "target\wasm32v1-none\release\fuel_lock.wasm" --source admin --network testnet 2>&1
$FUEL_LOCK_ID = ($output | Select-String -Pattern '^C[A-Z0-9]{55}$').Line
if ($FUEL_LOCK_ID -match '^C[A-Z0-9]{55}$') {
    Write-Host "        SUCCESS: $FUEL_LOCK_ID" -ForegroundColor Green
    Add-Content -Path $envFile -Value "FUEL_LOCK_CONTRACT_ID=$FUEL_LOCK_ID"
} else {
    Write-Host "        ERROR: Failed to deploy fuel-lock" -ForegroundColor Red
    exit 1
}

# Deploy voucher-redemption
Write-Host "  [3/5] Deploying voucher-redemption..." -ForegroundColor Cyan
$output = stellar contract deploy --wasm "target\wasm32v1-none\release\voucher_redemption.wasm" --source admin --network testnet 2>&1
$VOUCHER_ID = ($output | Select-String -Pattern '^C[A-Z0-9]{55}$').Line
if ($VOUCHER_ID -match '^C[A-Z0-9]{55}$') {
    Write-Host "        SUCCESS: $VOUCHER_ID" -ForegroundColor Green
    Add-Content -Path $envFile -Value "VOUCHER_REDEMPTION_CONTRACT_ID=$VOUCHER_ID"
} else {
    Write-Host "        ERROR: Failed to deploy voucher-redemption" -ForegroundColor Red
    exit 1
}

# Deploy credit-score
Write-Host "  [4/5] Deploying credit-score..." -ForegroundColor Cyan
$output = stellar contract deploy --wasm "target\wasm32v1-none\release\credit_score.wasm" --source admin --network testnet 2>&1
$CREDIT_SCORE_ID = ($output | Select-String -Pattern '^C[A-Z0-9]{55}$').Line
if ($CREDIT_SCORE_ID -match '^C[A-Z0-9]{55}$') {
    Write-Host "        SUCCESS: $CREDIT_SCORE_ID" -ForegroundColor Green
    Add-Content -Path $envFile -Value "CREDIT_SCORE_CONTRACT_ID=$CREDIT_SCORE_ID"
} else {
    Write-Host "        ERROR: Failed to deploy credit-score" -ForegroundColor Red
    exit 1
}

# Deploy geofencing
Write-Host "  [5/5] Deploying geofencing..." -ForegroundColor Cyan
$output = stellar contract deploy --wasm "target\wasm32v1-none\release\geofencing.wasm" --source admin --network testnet 2>&1
$GEOFENCING_ID = ($output | Select-String -Pattern '^C[A-Z0-9]{55}$').Line
if ($GEOFENCING_ID -match '^C[A-Z0-9]{55}$') {
    Write-Host "        SUCCESS: $GEOFENCING_ID" -ForegroundColor Green
    Add-Content -Path $envFile -Value "GEOFENCING_CONTRACT_ID=$GEOFENCING_ID"
} else {
    Write-Host "        ERROR: Failed to deploy geofencing" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Contract IDs:" -ForegroundColor Cyan
Write-Host "  Fuel Token:          $FUEL_TOKEN_ID" -ForegroundColor White
Write-Host "  Fuel Lock:           $FUEL_LOCK_ID" -ForegroundColor White
Write-Host "  Voucher Redemption:  $VOUCHER_ID" -ForegroundColor White
Write-Host "  Credit Score:        $CREDIT_SCORE_ID" -ForegroundColor White
Write-Host "  Geofencing:          $GEOFENCING_ID" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Get your admin secret key: stellar keys show admin" -ForegroundColor White
Write-Host "2. Add it to backend/.env as STELLAR_ADMIN_SECRET" -ForegroundColor White
Write-Host "3. Update Flutter app stellar_service.dart with contract IDs" -ForegroundColor White
Write-Host "4. Run 'npm run dev' in backend folder to start the server" -ForegroundColor White
Write-Host ""

# Save contract IDs to a text file
$contractIdsFile = "CONTRACT_IDS.txt"
@"
FuelAnchor Contract IDs - Stellar Testnet
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

FUEL_TOKEN_CONTRACT_ID=$FUEL_TOKEN_ID
FUEL_LOCK_CONTRACT_ID=$FUEL_LOCK_ID
VOUCHER_REDEMPTION_CONTRACT_ID=$VOUCHER_ID
CREDIT_SCORE_CONTRACT_ID=$CREDIT_SCORE_ID
GEOFENCING_CONTRACT_ID=$GEOFENCING_ID

Admin Address: $adminAddress
Network: Stellar Testnet
RPC URL: https://soroban-testnet.stellar.org:443

Update Flutter app at:
frontend_flutter/lib/features/blockchain/data/services/stellar_service.dart

Line 17-18:
static const String _fuelAssetIssuer = '$adminAddress';
static const String _sorobanContractId = '$FUEL_LOCK_ID';
"@ | Out-File -FilePath $contractIdsFile -Encoding UTF8

Write-Host "Contract IDs saved to CONTRACT_IDS.txt" -ForegroundColor Green
