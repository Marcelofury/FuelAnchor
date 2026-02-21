# FuelAnchor Setup Commands
# Run from project root: C:\Users\USER\FuelAnchor

Write-Host "🚀 Setting up FuelAnchor..." -ForegroundColor Cyan
Write-Host ""

# 1. Install backend test dependencies
Write-Host "📦 Installing backend test dependencies..." -ForegroundColor Yellow
Set-Location backend
npm install --save-dev @types/jest @types/supertest jest supertest ts-jest
npm install swagger-ui-express yamljs @types/swagger-ui-express @types/yamljs
Set-Location ..
Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
Write-Host ""

# 2. Install Flutter dependencies
Write-Host "📱 Installing Flutter dependencies..." -ForegroundColor Yellow
Set-Location frontend_flutter
flutter pub get
Write-Host "✅ Flutter dependencies installed" -ForegroundColor Green
Write-Host ""

# 3. Run Flutter build_runner (CRITICAL)
Write-Host "⚙️ Running Flutter code generation..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
Write-Host "✅ Code generation complete" -ForegroundColor Green
Set-Location ..
Write-Host ""

# 4. Generate contract bindings
Write-Host "🔗 Generating contract bindings..." -ForegroundColor Yellow
if (Test-Path "CONTRACT_IDS.txt") {
    Set-Location scripts
    .\generate_contract_bindings.ps1
    Set-Location ..
    Write-Host "✅ Contract bindings generated" -ForegroundColor Green
} else {
    Write-Host "⚠️  CONTRACT_IDS.txt not found. Deploy contracts first with:" -ForegroundColor Yellow
    Write-Host "   cd scripts" -ForegroundColor White
    Write-Host "   .\deploy_contracts.ps1" -ForegroundColor White
}
Write-Host ""

# 5. Run backend tests
Write-Host "🧪 Running backend tests..." -ForegroundColor Yellow
Set-Location backend
npm test
Set-Location ..
Write-Host ""

Write-Host "✅ Setup complete!" -ForegroundColor Green
