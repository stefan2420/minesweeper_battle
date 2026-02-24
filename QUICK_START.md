# Quick Start Guide - Ranked Qualifiers & Dev Account System

## ✅ Implementation Complete

All code has been successfully implemented and verified:
- ✅ Flutter code compiles without errors (40 info-level warnings, all pre-existing)
- ✅ TypeScript Cloud Functions compile without errors
- ✅ All 13 implementation tasks completed

## Next Steps to Deploy

### 1. Deploy Cloud Functions (5 minutes)

```bash
cd /Users/4gps/Documents/MyProjects/minesweeper_battle
firebase deploy --only functions
```

This deploys:
- `bootstrapFirstAdmin` - Creates your admin account
- `grantDevRole` - Allows you to grant roles to others
- `migrateQualifierSystem` - Migrates existing user data

### 2. Deploy Firestore Rules (1 minute)

```bash
firebase deploy --only firestore:rules
```

This deploys the updated security rules that protect the config and prevent privilege escalation.

### 3. Run Migration (2 minutes)

```bash
firebase functions:call migrateQualifierSystem
```

This will:
- Create `/appConfig/ranked` document with `qualifierMatchCount: 3`
- Update all existing users to set `isInQualifiers: false` (already ranked)
- Update all existing users to set `role: 'user'`

### 4. Make Yourself an Admin (1 minute)

Replace `YOUR_EMAIL@gmail.com` with your actual Google account email:

```bash
firebase functions:call bootstrapFirstAdmin --data '{"email":"YOUR_EMAIL@gmail.com"}'
```

### 5. Test the App (5 minutes)

```bash
# Run on your device/emulator
flutter run

# Or build for release
flutter build appbundle  # Android
flutter build ipa        # iOS
```

**What to test:**
1. Login with your admin account
2. Look for the purple developer icon (🔧) in the home screen header
3. Tap it to open Dev Settings
4. Try changing the qualifier count and saving
5. Create a test account to verify qualifiers work

### 6. Deploy to Production (10 minutes)

Once tested locally, deploy to your users:

**Android:**
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

**iOS:**
```bash
flutter build ipa --release
# Upload to App Store Connect via Xcode
```

## Quick Verification Checklist

After deployment, verify everything works:

- [ ] Your user document in Firestore has `role: "admin"`
- [ ] `/appConfig/ranked` document exists with `qualifierMatchCount: 3`
- [ ] You can see the purple dev icon in the app
- [ ] Dev Settings screen loads and shows current config
- [ ] You can change and save the qualifier count
- [ ] New test accounts show "Qualifier 0/3" in their profile
- [ ] After 3 battles, test accounts show their actual rank

## Configuration

The qualifier system is now live with default settings:
- **Qualifier Count:** 3 matches
- **Your Role:** Admin (full permissions)

To change the qualifier count:
1. Open the app
2. Tap the purple developer icon
3. Adjust the slider (0-10)
4. Tap "Save Configuration"

**Setting to 0 disables qualifiers** (instant ranking for new users)

## Documentation

For more details, see:
- `QUALIFIER_IMPLEMENTATION_SUMMARY.md` - Complete technical documentation
- `QUALIFIER_DEPLOYMENT.md` - Detailed deployment guide with troubleshooting

## Support

If you encounter issues:
1. Check the detailed troubleshooting section in `QUALIFIER_DEPLOYMENT.md`
2. Verify Firestore rules deployed correctly
3. Check Cloud Functions logs in Firebase Console
4. Ensure ConfigService initialized in main.dart

## What This System Does

### For New Players
- Must complete 3 qualifier matches before rank is revealed
- See "Qualifier X/3" progress instead of rank
- Still gain/lose ELO during qualifiers (for fair matchmaking)
- Rank revealed after completing qualifiers

### For You (Admin/Dev)
- Purple developer icon in home screen
- Real-time config adjustment (no redeployment needed)
- Change qualifier count from 0-10
- Grant dev/admin roles to other users
- View config update metadata

### Security
- Users cannot modify their own roles
- Only admins can grant roles
- Config changes logged with audit trail
- Firestore rules enforce all permissions

## Time to Deploy

**Total time:** ~25 minutes
- Functions deploy: ~5 min
- Rules deploy: ~1 min
- Migration: ~2 min
- Bootstrap admin: ~1 min
- Testing: ~5 min
- Production build: ~10 min

Ready to deploy? Start with step 1 above! 🚀
