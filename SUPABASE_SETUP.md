# Supabase Setup Guide for FuelAnchor

##  Quick Start

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create a free account
2. Click "New Project"
3. Fill in:
   - **Name**: `FuelAnchor`
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to East Africa (e.g., Singapore or Frankfurt)
4. Wait for project to be created (~2 minutes)

### 2. Get API Credentials

1. Once created, go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxxxxxxxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long string)

### 3. Configure Flutter App

Open `frontend_flutter/lib/core/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';  // ← Paste Project URL
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';  // ← Paste anon key
```

### 4. Run Database Migration

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase/migrations/20260207_initial_schema.sql`
4. Paste into the query editor
5. Click **Run** (green play button)
6. You should see "Success. No rows returned" ✅

### 5. Verify Tables Created

Go to **Table Editor** and you should see:
- ✅ profiles
- ✅ rider_profiles
- ✅ fleet_driver_profiles
- ✅ merchant_profiles
- ✅ transactions
- ✅ fuel_quotas

---

## 🧪 Testing the Setup

### Run the Flutter App

```bash
cd frontend_flutter
flutter pub get
flutter run
```

### Register a Test User

1. Tap **"Enter Platform"** on welcome screen
2. Tap **"Register"** on login screen
3. Fill in:
   - **Role**: Choose Rider/Fleet Driver/Merchant
   - **Full Name**: Test User
   - **Phone**: 0712345678
   - **ID**: Any number
4. Tap **"CREATE ACCOUNT"**

If Supabase is configured correctly, you'll see:
- ✅ "Account created in database!" message
- ✅ Navigate to dashboard

### Verify in Supabase

1. Go to **Table Editor** → **profiles**
2. You should see your new user with:
   - `full_name`, `phone_number`, `role`, `stellar_public_key`

---

## 🔒 Security Features

### Row Level Security (RLS)

The database has RLS enabled so users can only:
- ✅ View their own profile
- ✅ Update their own profile
- ✅ View transactions they're part of
- ❌ Cannot view other users' data

### Authentication

- Users authenticate with Supabase Auth
- Stellar keypair is stored locally (encrypted with flutter_secure_storage)
- Profile linked to Stellar public key for on-chain transactions

---

## 🌍 Local-Only Mode (No Supabase)

If you DON'T configure Supabase, the app still works in **local mode**:
- ✅ Stellar keypairs stored locally
- ✅ Transactions on Stellar testnet
- ❌ No profile backup in database
- ❌ Data lost if app uninstalled

To enable full features, configure Supabase!

---

## 📊 Database Schema

### profiles
Main user table extended from `auth.users`
- `id` - UUID link to Supabase Auth
- `full_name` - User's name
- `phone_number` - Phone for mobile money
- `role` - 'rider', 'fleet_driver', or 'merchant'
- `stellar_public_key` - Link to blockchain identity

### rider_profiles
Extra data for riders
- `national_id` - Optional ID number
- `total_fuel_purchased` - Lifetime fuel bought
- `credit_score` - On-chain credit score

### fleet_driver_profiles
Extra data for fleet drivers
- `vehicle_id` - Vehicle registration
- `odometer_reading` - Current odometer
- `fuel_quota_allocated` - Monthly fuel limit
- `fuel_quota_used` - Fuel used this period

### merchant_profiles
Extra data for fuel stations
- `station_id` - Station identifier
- `location_lat/lng` - GPS coordinates
- `total_fuel_dispensed` - Lifetime sales

### transactions
All blockchain transactions synced
- `blockchain_hash` - Stellar transaction ID
- `from_user_id` - Payer
- `to_user_id` - Merchant
- `amount` - FUEL tokens
- `gps_lat/lng` - GPS verification

---

##  Troubleshooting

### "Supabase not configured" warning

**Cause**: Config file still has placeholder values

**Fix**: Update `supabase_config.dart` with real credentials

### "Failed to create profile" error

**Cause**: Database migration not run

**Fix**: Run SQL migration in Supabase SQL Editor

### "Row Level Security" error

**Cause**: RLS policies not created

**Fix**: Re-run the full migration SQL (it's safe to run multiple times)

### Testing with Multiple Users

1. Sign out in app (or clear app data)
2. Register new user with different phone
3. Both users should appear in `profiles` table

---

## 🚀 Production Checklist

Before deploying to production:

- [ ] Update Supabase project to paid plan (for better limits)
- [ ] Enable 2FA on Supabase dashboard
- [ ] Set up database backups (Settings → Database → Backups)
- [ ] Configure custom SMTP for email verification
- [ ] Add proper error monitoring (Sentry integration)
- [ ] Test RLS policies thoroughly
- [ ] Set up Supabase Edge Functions for backend logic

---

## 📚 Resources

- [Supabase Flutter Docs](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [FuelAnchor Architecture](../ARCHITECTURE.md)

---

**Need Help?** Open an issue on GitHub or check the main README.
