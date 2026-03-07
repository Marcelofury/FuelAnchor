# Simple Username/Password Authentication Setup

## Overview
Your app now uses **simple username/password authentication** stored directly in the Supabase database, without requiring Supabase Auth or email verification.

## Database Migration Required

### Step 1: Run SQL Migration in Supabase

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Open your project: `FuelAnchor`
3. Navigate to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy and paste the contents of: `supabase/migrations/20260307_simple_auth.sql`
6. Click **Run** to execute the migration

This migration will:
- ✅ Add `username` and `password_hash` columns to profiles table
- ✅ Remove foreign key dependency on Supabase Auth
- ✅ Add fleet_manager role support
- ✅ Create fleet_manager_profiles table
- ✅ Update Row Level Security policies to work without auth.uid()
- ✅ Create indexes for username and phone lookups

### Step 2: Verify Migration

Run this query in Supabase SQL Editor to verify:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('username', 'password_hash');
```

You should see both columns listed.

## How It Works

### Registration Flow
```
1. User enters: username, password, name, phone, role
2. App generates Stellar blockchain wallet
3. App hashes password (simple hash)
4. App stores user in database:
   - profiles table: username, password_hash, name, phone, role
   - role-specific table: rider_profiles, fleet_driver_profiles, etc.
5. User logged in and navigated to dashboard
```

### Login Flow
```
1. User enters: username, password
2. App hashes password
3. App queries database: SELECT * FROM profiles WHERE username = ? AND password_hash = ?
4. If match found: user logged in
5. If no match: "Invalid username or password"
```

### Data Storage

| Data Type | Location | Example |
|-----------|----------|---------|
| Username | `profiles.username` | "john_doe" |
| Password | `profiles.password_hash` | "123456789" (hashed) |
| Name | `profiles.full_name` | "John Doe" |
| Phone | `profiles.phone_number` | "+254712345678" |
| Role | `profiles.role` | "rider" / "fleet_driver" / "fleet_manager" / "merchant" |
| Stellar Key | `profiles.stellar_public_key` | "GDBX..." |

## Security Notes

### Current Implementation (Development)
- Uses simple `.hashCode()` for password hashing
- **NOT suitable for production**
- Easy to implement and test

### Production Recommendations
1. **Use proper password hashing:**
   - Install `crypto` package in Flutter
   - Use bcrypt, argon2, or scrypt
   - Add salt to passwords

2. **Example with crypto package:**
```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

static String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}
```

3. **Even better: Server-side hashing**
   - Add a backend API endpoint
   - Hash passwords on server using bcrypt
   - Never send plain passwords over network

## Testing

### Test Registration
1. Open app
2. Click "Create Account"
3. Enter:
   - Username: `test_user`
   - Password: `password123`
   - Name: `Test User`
   - Phone: `+254700000000`
   - Select role: Rider
4. Click "Register"
5. Should create account and navigate to dashboard

### Test Login
1. Open app
2. Enter username: `test_user`
3. Enter password: `password123`
4. Click "Login"
5. Should authenticate and navigate to dashboard

### Verify in Database
```sql
-- Check if user was created
SELECT username, full_name, phone_number, role 
FROM profiles 
WHERE username = 'test_user';

-- Should return your test user data
```

## Benefits of This Approach

✅ **No email required** - Users can register with just username/phone  
✅ **No email verification** - Instant account creation  
✅ **Simple to understand** - Direct database queries  
✅ **Works offline** - Can cache credentials locally  
✅ **Fast authentication** - Single database query  
✅ **Phone-based** - Perfect for East African users without emails  

## Table Schema

### profiles table
```sql
id                  UUID PRIMARY KEY
username            TEXT UNIQUE NOT NULL
password_hash       TEXT NOT NULL
full_name           TEXT NOT NULL
phone_number        TEXT NOT NULL UNIQUE
role                TEXT CHECK (role IN ('rider', 'fleet_driver', 'fleet_manager', 'merchant'))
stellar_public_key  TEXT UNIQUE NOT NULL
created_at          TIMESTAMPTZ
updated_at          TIMESTAMPTZ
```

## Next Steps

1. ✅ Run the migration in Supabase SQL Editor
2. ✅ Test registration with new account
3. ✅ Test login with created account
4. ✅ Build APK and deploy
5. ⚠️ Before production: Implement proper password hashing

## Troubleshooting

### "Username already exists"
- Username must be unique across all users
- Try different username

### "Phone number already registered"
- Each phone can only register once
- Use different phone number

### "Supabase is not configured"
- Check `lib/core/config/supabase_config.dart`
- Ensure Supabase URL and API key are set

### Migration fails
- Check if you have admin access to Supabase
- Ensure you're running query in correct project
- Check SQL Editor for error messages
