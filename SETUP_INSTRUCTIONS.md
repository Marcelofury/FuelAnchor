# Quick Setup Guide

## Current Issues Fixed ✅

1. **Jest configuration corrected** - Removed package.json fields from jest.config.json
2. **TypeScript transformation configured** - Added ts-jest transform with proper settings
3. **Path navigation script created** - setup.ps1 navigates correctly

## Run Setup (From Project Root)

```powershell
# Make sure you're in C:\Users\USER\FuelAnchor
cd C:\Users\USER\FuelAnchor

# Run the setup script
.\setup.ps1
```

**OR run commands individually:**

```powershell
# 1. Backend dependencies (from root)
cd backend
npm install --save-dev @types/jest @types/supertest jest supertest ts-jest
npm install swagger-ui-express yamljs @types/swagger-ui-express @types/yamljs
cd ..

# 2. Flutter dependencies (from root)
cd frontend_flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
cd ..

# 3. Contract bindings (from root) - Only if CONTRACT_IDS.txt exists
cd scripts
.\generate_contract_bindings.ps1
cd ..

# 4. Run tests (from root)
cd backend
npm test
cd ..
```

## What Was Fixed

### 1. Jest Configuration
**Before** (incorrect):
```json
{
  "name": "fuelanchor-backend-tests",  ❌ Package.json fields
  "version": "1.0.0",                  ❌ 
  "jest": { ... }                       ❌ Nested config
}
```

**After** (correct):
```json
{
  "preset": "ts-jest",                  ✅ Direct config
  "testEnvironment": "node",            ✅
  "transform": {                        ✅ TypeScript transform
    "^.+\\.ts$": ["ts-jest", { ... }]
  }
}
```

### 2. TypeScript Import Errors
Added explicit `transform` configuration to handle ES6 imports in TypeScript test files.

### 3. Path Navigation
Commands now navigate from project root instead of trying to cd from backend directory.

## Expected Test Output

After running `npm test`, you should see:
```
Test Suites: 3 passed, 3 total
Tests:       XX passed, XX total
Coverage: XX% statements, XX% branches, XX% functions, XX% lines
```

## Security Vulnerabilities

The npm warnings about 33 high severity vulnerabilities are from development dependencies. To address:

```powershell
cd backend
npm audit fix
# OR for more aggressive fixes (may break tests):
npm audit fix --force
```

## Next Steps After Tests Pass

1. **Commit all changes**:
   ```bash
   git add .
   git commit -m "Fixed Jest configuration and added remaining features"
   git push origin main
   ```

2. **Verify deployments work**:
   ```powershell
   cd scripts
   .\deploy_contracts.ps1  # Deploy contracts
   .\generate_contract_bindings.ps1  # Generate bindings
   cd ..
   ```

3. **Start development servers**:
   ```powershell
   # Backend (terminal 1)
   cd backend
   npm run dev

   # Flutter (terminal 2)
   cd frontend_flutter
   flutter run
   ```

## Troubleshooting

### Tests still fail with "Cannot use import"
- Make sure `ts-jest` is installed: `npm list ts-jest`
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
- Check `tsconfig.json` has `"module": "commonjs"`

### Flutter build_runner fails
- Run from `frontend_flutter` directory, not root
- Ensure `pubspec.yaml` has `riverpod_annotation` and `build_runner`
- Try: `flutter clean && flutter pub get`

### Contract bindings fail
- Ensure Soroban CLI is installed: `soroban --version`
- Check `CONTRACT_IDS.txt` exists in project root
- Deploy contracts first with `.\scripts\deploy_contracts.ps1`

## Files Modified in This Fix

- ✅ `backend/jest.config.json` - Fixed configuration
- ✅ `setup.ps1` - Created automated setup script
- ✅ `SETUP_INSTRUCTIONS.md` - This file
