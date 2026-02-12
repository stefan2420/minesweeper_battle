# Minesweeper Battle Cloud Functions

This directory contains Firebase Cloud Functions for server-side validation and security enforcement.

## Functions Overview

### 1. validateGameOutcome
**Trigger:** Firestore `battleRooms/{roomCode}` on update (when status → 'finished')
**Purpose:** Validates winner's grid to prevent cheating

**What it checks:**
- Grid dimensions match difficulty
- Mine count is correct
- Winner didn't hit a mine
- Winner revealed all non-mine cells
- Finish time is reasonable (5 seconds - 24 hours)

**On validation failure:**
- Logs to `suspiciousGames` collection
- Can optionally auto-revert the win (currently commented out)

### 2. rateLimitRoomCreation
**Trigger:** Firestore `battleRooms/{roomCode}` on create
**Purpose:** Prevents spam room creation

**Limits:**
- Max 5 rooms per minute per user

**On limit exceeded:**
- Deletes the newly created room
- Logs to `rateLimitViolations` collection

### 3. rateLimitRoomJoining
**Trigger:** Firestore `battleRooms/{roomCode}` on update (when guestId added)
**Purpose:** Prevents spam room joining

**Limits:**
- Max 10 room joins per minute per user

**On limit exceeded:**
- Reverts the guest addition
- Logs to `rateLimitViolations` collection

### 4. auditBattleWinner
**Trigger:** Firestore `battleRooms/{roomCode}` on update (when winnerId changes)
**Purpose:** Logs all battle wins for audit trail

**Logs to:** `auditLogs` collection

### 5. auditUserStats
**Trigger:** Firestore `users/{userId}` on update
**Purpose:** Detects suspicious stat changes

**Monitors:**
- XP changes > 100 at once
- Elo rating changes > 100 at once
- Stat decreases (should never happen with monotonic stats)

**Logs to:** `auditLogs` collection

### 6. auditRapidRoomCreation
**Trigger:** Firestore `battleRooms/{roomCode}` on create
**Purpose:** Flags users creating many rooms rapidly

**Threshold:**
- More than 10 rooms in 5 minutes

**Logs to:** `auditLogs` collection

### 7. cleanupExpiredRooms
**Trigger:** Cloud Scheduler (daily at midnight UTC)
**Purpose:** Delete old rooms to reduce database size and attack surface

**Deletes:**
- Rooms older than 24 hours
- Associated privateData subcollections

**Batch size:** 500 rooms per batch (Firestore limit)

## Development

### Install dependencies
```bash
npm install
```

### Build TypeScript
```bash
npm run build
```

### Run locally with emulator
```bash
npm run serve
```

### Deploy to Firebase
```bash
npm run deploy
```

### View logs
```bash
npm run logs
```

## Project Structure

```
functions/
├── src/
│   ├── index.ts                    # Entry point - exports all functions
│   ├── validateGameOutcome.ts      # Game validation logic
│   ├── rateLimit.ts                # Rate limiting enforcement
│   ├── cleanupExpiredRooms.ts      # Scheduled cleanup
│   └── auditLog.ts                 # Audit logging
├── lib/                             # Compiled JavaScript (gitignored)
├── package.json                     # Dependencies
├── tsconfig.json                    # TypeScript config
└── .eslintrc.js                     # ESLint config
```

## Configuration

### Rate Limits (in rateLimit.ts)
```typescript
const LIMITS = {
  roomCreation: 5,      // per minute
  roomJoining: 10,      // per minute
  progressUpdate: 100,  // per minute (not implemented yet)
};
```

### Grid Configs (in validateGameOutcome.ts)
```typescript
const GRID_CONFIGS = {
  "beginner": { rows: 9, cols: 9, mines: 10 },
  "intermediate": { rows: 16, cols: 16, mines: 40 },
  "expert": { rows: 16, cols: 30, mines: 99 },
};
```

### Cleanup Schedule (in cleanupExpiredRooms.ts)
```typescript
.schedule("0 0 * * *")  // Daily at midnight UTC
```

## Testing

### Test locally with emulator
```bash
# Install emulators
firebase init emulators

# Start emulators
firebase emulators:start

# Functions will be available at http://localhost:5001
```

### Test validateGameOutcome
1. Create a battle room
2. Set status to 'finished' with winnerId
3. Check function logs for validation results
4. Check `suspiciousGames` collection for flagged games

### Test rate limiting
1. Create 6 rooms rapidly
2. 6th room should be deleted
3. Check `rateLimitViolations` collection

### Test audit logging
1. Complete a battle (check `auditLogs` for winner)
2. Update user XP by 200 (check `auditLogs` for large change)
3. Create 11 rooms in 5 minutes (check `auditLogs` for rapid creation)

## Monitoring

### View function logs
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only validateGameOutcome

# Follow in real-time
firebase functions:log --only validateGameOutcome --tail
```

### Check function status
```bash
firebase functions:list
```

### Monitor costs
Firebase Console → Usage and billing → Functions

## Troubleshooting

### Function fails to deploy
```bash
# Clean and rebuild
rm -rf node_modules lib
npm install
npm run build
firebase deploy --only functions
```

### Function timeout errors
Increase timeout in function definition:
```typescript
export const myFunction = functions
  .runWith({ timeoutSeconds: 300 })
  .firestore.document(...)
```

### Rate limit memory resets
Rate limits are stored in-memory and reset on cold starts. For persistent rate limiting, implement Firestore-based tracking.

### Cloud Scheduler not working
Enable the API:
```bash
gcloud services enable cloudscheduler.googleapis.com
```

## Performance

### Typical execution times
- validateGameOutcome: 200-500ms
- rateLimitRoomCreation: 50-100ms
- auditLog functions: 50-100ms
- cleanupExpiredRooms: 1-5 seconds (depends on room count)

### Cold start times
- First invocation: 2-5 seconds
- Warm invocations: 100-500ms

### Cost per invocation
- ~$0.0000004 per invocation
- ~$0.0000025 per GB-second of compute

## Security Notes

### Admin SDK Permissions
Functions use Firebase Admin SDK with full database access. Ensure:
- Function code is trusted
- Dependencies are kept up-to-date
- Service account permissions are minimal

### Rate Limit Bypassing
Current in-memory rate limiting can be bypassed by:
- Cold starts (memory resets)
- Multiple Firebase regions

For production, consider:
- Redis-based rate limiting
- Firestore-based persistent tracking
- Firebase Extensions rate limiting

### Validation Edge Cases
Current validation doesn't check:
- Mine distribution patterns (could detect mine pattern manipulation)
- Cell adjacency counts (could detect grid tampering)
- Play patterns (could detect bots)

Consider adding these for stronger anti-cheat.

## Future Enhancements

### Planned improvements
- [ ] Firestore-based persistent rate limiting
- [ ] Machine learning-based cheat detection
- [ ] Player behavior analysis
- [ ] Grid pattern validation
- [ ] Timing analysis (detect impossible solve times)

### Optional features
- [ ] Replay validation (store and validate move sequences)
- [ ] Leaderboard validation (detect stat anomalies)
- [ ] Automated ban system for repeat offenders
- [ ] Admin dashboard for reviewing suspicious games

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review function source code
3. Test locally with emulator
4. Check Firebase documentation: https://firebase.google.com/docs/functions
