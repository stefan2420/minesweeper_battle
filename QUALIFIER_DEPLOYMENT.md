# Qualifier System Deployment Guide

This guide provides step-by-step instructions for deploying the Ranked Qualifiers & Dev Account System.

## Prerequisites

- Firebase CLI installed and authenticated
- Project configured in Firebase console
- Current working directory: `/Users/4gps/Documents/MyProjects/minesweeper_battle`

## Deployment Steps

### Step 1: Initialize ConfigService

The ConfigService needs to be initialized when the app starts to load configuration from Firestore.

**File:** `lib/main.dart`

Add the following before `runApp()`:

```dart
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize config service
  await ConfigService.instance.loadConfig();

  runApp(const MyApp());
}
```

### Step 2: Deploy Firestore Security Rules

Deploy the updated security rules that include role-based permissions:

```bash
firebase deploy --only firestore:rules
```

Verify the deployment:
- Go to Firebase Console → Firestore Database → Rules
- Confirm the new rules include `isDevUser()` and `isAdminUser()` functions
- Confirm `/appConfig` collection has proper read/write permissions

### Step 3: Deploy Cloud Functions

Build and deploy the new Cloud Functions for role management and migration:

```bash
cd functions
npm install  # Install any new dependencies
npm run build
cd ..
firebase deploy --only functions
```

This will deploy:
- `bootstrapFirstAdmin` - Creates the first admin user
- `grantDevRole` - Allows admins to grant roles to other users
- `migrateQualifierSystem` - One-time migration for existing data

### Step 4: Run Data Migration

The migration function will:
1. Create the `/appConfig/ranked` document with `qualifierMatchCount: 3`
2. Update all existing users to set `isInQualifiers: false` (they're already ranked)
3. Update all existing users to set `role: 'user'` if not set

**Option A: Via Firebase CLI (Recommended)**

```bash
firebase functions:call migrateQualifierSystem
```

**Option B: Via Firebase Console**

1. Go to Firebase Console → Functions
2. Find `migrateQualifierSystem` function
3. Click "Test" tab
4. Run the function with empty payload `{}`

**Expected Output:**
```json
{
  "success": true,
  "message": "Migration completed successfully",
  "stats": {
    "configCreated": true,
    "usersUpdated": <number>,
    "errors": []
  }
}
```

### Step 5: Bootstrap First Admin Account

Replace `YOUR_EMAIL@example.com` with your Google account email:

```bash
firebase functions:call bootstrapFirstAdmin --data '{"email":"YOUR_EMAIL@example.com"}'
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Admin role granted to YOUR_EMAIL@example.com",
  "userId": "abc123..."
}
```

### Step 6: Verify in Firestore

Open Firebase Console → Firestore Database and verify:

1. **`/appConfig/ranked` document exists:**
   ```
   qualifierMatchCount: 3
   updatedAt: <timestamp>
   updatedBy: "migration_system"
   ```

2. **Your user document has admin role:**
   ```
   /users/<your-user-id>
   {
     role: "admin",
     stats: {
       isInQualifiers: false,
       ...
     }
   }
   ```

3. **All existing users have been migrated:**
   - Check a few random user documents
   - Verify they have `role: "user"` and `stats.isInQualifiers: false`

### Step 7: Deploy Flutter App

Build and deploy the updated Flutter app:

**Android:**
```bash
flutter build appbundle
# Upload to Google Play Console
```

**iOS:**
```bash
flutter build ipa
# Upload to App Store Connect
```

**Or run locally for testing:**
```bash
flutter run
```

### Step 8: Verify Functionality

1. **Login with your admin account**
   - You should see a purple developer icon in the home screen header

2. **Access Dev Settings**
   - Tap the purple developer icon
   - Verify the "Qualifier Match Count" slider shows the current value (3)
   - Try changing it to a different value (e.g., 5) and saving
   - Verify the success message appears

3. **Test with a new account**
   - Create a new test account
   - Navigate to Profile
   - Verify it shows "Qualifier 0/3" instead of a rank
   - Play one ranked battle
   - Verify it shows "Qualifier 1/3"
   - Continue until you reach the threshold
   - Verify the rank is revealed after completing qualifiers

4. **Check Leaderboard**
   - Open the leaderboard
   - Verify existing players show their ranks normally
   - Verify qualifying players show "Q" badge with progress

## Troubleshooting

### ConfigService not loading

If the app crashes or config doesn't load:
- Verify `/appConfig/ranked` document exists in Firestore
- Check Firestore rules allow authenticated users to read `/appConfig`
- Check Flutter console for error messages from ConfigService

### Admin role not working

If dev icon doesn't appear:
- Verify your user document has `role: "admin"` in Firestore
- Try logging out and logging back in
- Check that UserModel.isDev getter is working properly

### Dev Settings can't save

If saving fails:
- Check Firestore rules allow dev/admin users to write to `/appConfig`
- Verify the value is between 0-10 (validation range)
- Check browser/app console for error messages

### Migration didn't run

If users still don't have the new fields:
- Check Cloud Functions logs in Firebase Console
- Verify the migration function was called successfully
- Manually update a test user document to verify rules work

## Rollback Plan

If you need to rollback:

1. **Disable qualifiers immediately:**
   ```
   Go to Dev Settings → Set qualifier count to 0 → Save
   ```
   This gives all new users instant ranking.

2. **Revert Firestore rules:**
   ```bash
   git checkout HEAD~1 firestore.rules
   firebase deploy --only firestore:rules
   ```

3. **Revert app code:**
   - Redeploy previous app version from git history
   - Or remove dev icon and qualifier UI conditionals

## Post-Deployment

### Grant roles to other developers

To grant dev role to another user:

1. Get their user ID from Firestore
2. Use your admin account to call the Cloud Function:

```dart
// In a Flutter app with admin privileges
final functions = FirebaseFunctions.instance;
final grantRole = functions.httpsCallable('grantDevRole');

await grantRole.call({
  'userId': 'other-user-id',
  'role': 'dev', // or 'admin'
});
```

### Monitor audit logs

All role changes and config updates are logged to `/auditLogs` collection. Review periodically for security monitoring.

### Adjust qualifier count

Based on player feedback, you can adjust the qualifier count through Dev Settings without redeployment.

## Summary

✅ Firestore rules deployed with role-based permissions
✅ Cloud Functions deployed (role management + migration)
✅ Data migrated (config created, existing users updated)
✅ First admin account bootstrapped
✅ Flutter app deployed with qualifier system
✅ Dev settings accessible to admin users

The qualifier system is now live!
