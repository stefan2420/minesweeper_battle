# Security Remediation Deployment Guide

This guide walks you through deploying the security fixes for Minesweeper Battle multiplayer game.

## Overview

The security remediation includes:
- ✅ Firestore security rules (CRITICAL)
- ✅ Cloud Functions for server-side validation
- ✅ Input sanitization and bounds checking
- ✅ Rate limiting
- ✅ Audit logging
- ✅ Automated room cleanup

## Prerequisites

1. **Firebase CLI installed**
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase project authenticated**
   ```bash
   firebase login
   firebase use minesweep-battle
   ```

3. **Node.js 18 or higher**
   ```bash
   node --version
   ```

## Deployment Steps

### Step 1: Deploy Firestore Security Rules (CRITICAL - Do This First!)

**Why this is critical:** Your database is currently unprotected. Deploy this IMMEDIATELY.

```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules
```

**Verify deployment:**
1. Go to Firebase Console → Firestore Database → Rules
2. Confirm the rules were updated with timestamp
3. Check that rules include authentication checks

**Expected output:**
```
✔  firestore: rules file firestore.rules compiled successfully
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

### Step 2: Install Cloud Functions Dependencies

```bash
cd functions
npm install
```

**This installs:**
- firebase-admin (v12.0.0)
- firebase-functions (v4.5.0)
- TypeScript and ESLint tooling

### Step 3: Build Cloud Functions

```bash
npm run build
```

**This compiles:**
- `src/*.ts` → `lib/*.js`

**Verify build:**
```bash
ls -la lib/
# Should see: index.js, validateGameOutcome.js, rateLimit.js, etc.
```

### Step 4: Deploy Cloud Functions

```bash
# From the functions directory
npm run deploy

# Or from project root
firebase deploy --only functions
```

**Functions being deployed:**
1. `validateGameOutcome` - Validates game winners (prevents cheating)
2. `rateLimitRoomCreation` - Limits room creation to 5/min per user
3. `rateLimitRoomJoining` - Limits room joining to 10/min per user
4. `auditBattleWinner` - Logs winner changes
5. `auditUserStats` - Logs large XP/Elo changes
6. `auditRapidRoomCreation` - Flags rapid room creation
7. `cleanupExpiredRooms` - Daily cleanup (requires Cloud Scheduler)

**Expected deployment time:** 5-10 minutes

### Step 5: Enable Cloud Scheduler (for room cleanup)

The `cleanupExpiredRooms` function requires Cloud Scheduler:

```bash
# Enable Cloud Scheduler API
gcloud services enable cloudscheduler.googleapis.com --project=minesweep-battle
```

**Note:** Cloud Scheduler has a free tier (3 jobs/month free), then ~$0.10/job/month.

### Step 6: Verify Deployment

#### Check Firestore Rules
```bash
firebase firestore:indexes
```

#### Check Functions
```bash
firebase functions:list
```

**Expected output:**
```
┌─────────────────────────────────┬────────────┬─────────────┐
│ Function                        │ State      │ Trigger     │
├─────────────────────────────────┼────────────┼─────────────┤
│ validateGameOutcome             │ ACTIVE     │ firestore   │
│ rateLimitRoomCreation           │ ACTIVE     │ firestore   │
│ rateLimitRoomJoining            │ ACTIVE     │ firestore   │
│ auditBattleWinner              │ ACTIVE     │ firestore   │
│ auditUserStats                 │ ACTIVE     │ firestore   │
│ auditRapidRoomCreation         │ ACTIVE     │ firestore   │
│ cleanupExpiredRooms            │ ACTIVE     │ pubsub      │
└─────────────────────────────────┴────────────┴─────────────┘
```

#### Test Security Rules

Try these tests in Firebase Console:

**Test 1: Unauthenticated access (should FAIL)**
```
GET /battleRooms/ABC123
Auth: null
Expected: DENIED (permission-denied)
```

**Test 2: Accessing own room (should PASS)**
```
GET /battleRooms/ABC123
Auth: uid = hostId
Expected: ALLOWED
```

**Test 3: Accessing other's room (should FAIL)**
```
GET /battleRooms/ABC123
Auth: uid != hostId && uid != guestId
Expected: DENIED
```

### Step 7: Monitor Cloud Functions

#### View Logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only validateGameOutcome

# Follow logs in real-time
firebase functions:log --only validateGameOutcome --lines 50
```

#### Check for Errors
```bash
# View recent errors
gcloud logging read "resource.type=cloud_function AND severity>=ERROR" \
  --limit 50 --format json --project=minesweep-battle
```

## Post-Deployment Testing

### Test 1: Create and Join Room
1. Create a room as User A
2. Try to join as User B ✓ (should work)
3. Try to join as User C ✗ (should fail - room full)
4. Check error message is generic: "Cannot join room"

### Test 2: Input Sanitization
1. Try creating user with display name: `<script>alert('xss')</script>`
2. Expected: Name stored as `scriptalert('xss')script` (tags removed)

### Test 3: Bounds Validation
Test via app or Firebase Console:
```dart
// This should FAIL
battleService.updatePlayerProgress(
  roomCode: 'ABC123',
  playerId: 'user1',
  revealedCells: -5, // Invalid: negative
  flaggedCells: 200, // Invalid: exceeds max mines
);
// Expected error: ArgumentError
```

### Test 4: Game Outcome Validation
1. Complete a legitimate game → Check `suspiciousGames` collection (should be empty)
2. Manually set a winner in Firestore with invalid grid → Check `suspiciousGames` (should have entry)

### Test 5: Rate Limiting
1. Create 6 rooms rapidly as same user
2. 6th room should be auto-deleted
3. Check `rateLimitViolations` collection for log entry

## Rollback Plan (If Issues Occur)

### Rollback Firestore Rules
```bash
# Deploy previous rules version
firebase deploy --only firestore:rules --force
```

Or manually in Firebase Console:
1. Go to Firestore Database → Rules
2. Click "History" tab
3. Select previous version
4. Click "Restore"

### Rollback Cloud Functions
```bash
# Disable specific function
gcloud functions delete validateGameOutcome --region=us-central1 --project=minesweep-battle

# Or rollback to previous deployment
firebase deploy --only functions --force
```

## Cost Estimates

### Before Remediation
- **Risk:** Unbounded - vulnerable to abuse
- **Potential:** $1000s if attacked

### After Remediation (per 1000 games)
- **Firestore reads:** ~4000 reads × $0.036/100K = $0.14
- **Firestore writes:** ~2000 writes × $0.18/100K = $0.36
- **Cloud Functions:** ~7 invocations × $0.0000004/invocation = $0.003
- **Cloud Functions compute:** ~5 seconds × $0.0000025/GB-sec = $0.01
- **Cloud Scheduler:** 1 job × $0.10/month = $0.10/month (fixed)

**Total per 1000 games:** ~$0.50
**Monthly cost (10K games/month):** ~$5.10

## Monitoring Checklist

After deployment, monitor these collections in Firestore:

### Daily Checks (First Week)
- [ ] `suspiciousGames` - Flagged invalid wins
- [ ] `rateLimitViolations` - Abuse attempts
- [ ] `auditLogs` - Security events

### Weekly Checks
- [ ] Firebase Console → Authentication → Users (check for unusual growth)
- [ ] Firebase Console → Functions → Logs (check error rates)
- [ ] Firebase Console → Firestore → Usage (check costs)

### Security Alerts to Watch For
- Multiple entries in `suspiciousGames` from same user → Possible cheater
- High `rateLimitViolations` count → Possible DoS attempt
- Large XP/Elo changes in `auditLogs` → Possible stat manipulation

## Troubleshooting

### "Permission denied" errors after rule deployment
**Cause:** Rules are stricter now, some operations may fail.
**Fix:** Check that client code properly authenticates and only accesses own data.

### Cloud Functions failing to deploy
**Cause:** Build errors or dependency issues.
**Fix:**
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
```

### "Cloud Scheduler not enabled" error
**Fix:**
```bash
gcloud services enable cloudscheduler.googleapis.com --project=minesweep-battle
firebase deploy --only functions:cleanupExpiredRooms
```

### Functions timing out
**Cause:** Cold starts or heavy processing.
**Fix:** Increase timeout in function definition:
```typescript
export const myFunction = functions
  .runWith({ timeoutSeconds: 540 }) // 9 minutes max
  .firestore.document(...)
```

## Next Steps

After successful deployment:

1. **Test thoroughly** - Run through all game flows
2. **Monitor for 1 week** - Check logs and violation collections daily
3. **Phase 3 improvements** (optional):
   - Separate private game data to subcollection
   - Enhanced authorization checks
   - Add more audit logging events

## Getting Help

If you encounter issues:

1. Check Firebase Console logs
2. Review function error messages
3. Test security rules in Firebase Console → Firestore → Rules → Playground
4. Check this deployment guide's troubleshooting section

## Success Criteria

✅ Deployment successful if:
- [ ] Firestore rules active (check Firebase Console)
- [ ] All 7 Cloud Functions show "ACTIVE" status
- [ ] Test game completes successfully
- [ ] Unauthenticated access denied
- [ ] Invalid inputs rejected
- [ ] No errors in Cloud Functions logs

## Security Posture After Deployment

| Security Aspect | Before | After |
|----------------|--------|-------|
| Data Access Control | ❌ None | ✅ Strong |
| Game Integrity | ❌ Client-only | ✅ Server-validated |
| Input Validation | ❌ None | ✅ Sanitized |
| Rate Limiting | ❌ None | ✅ Active |
| Audit Logging | ❌ None | ✅ Comprehensive |
| **Overall Risk** | 🔴 CRITICAL | 🟢 LOW |

**Congratulations!** Your multiplayer game is now secure. 🎉
