import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// In-memory rate limit tracking
// Note: This resets on cold starts. For production, consider using Redis or Firestore
interface RateLimitEntry {
  count: number;
  resetTime: number;
}

const rateLimits: { [key: string]: RateLimitEntry } = {};

// Rate limit configurations (requests per minute)
const LIMITS = {
  roomCreation: 5,
  roomJoining: 10,
  progressUpdate: 100,
};

/**
 * Checks and enforces rate limits for user actions
 */
function checkRateLimit(userId: string, action: string, limit: number): boolean {
  const key = `${userId}:${action}`;
  const now = Date.now();
  const windowMs = 60000; // 1 minute

  if (!rateLimits[key] || now > rateLimits[key].resetTime) {
    // Start new window
    rateLimits[key] = {
      count: 1,
      resetTime: now + windowMs,
    };
    return true;
  }

  if (rateLimits[key].count >= limit) {
    // Rate limit exceeded
    return false;
  }

  // Increment counter
  rateLimits[key].count++;
  return true;
}

/**
 * Logs rate limit violations
 */
async function logViolation(
  userId: string,
  action: string,
  documentId: string
): Promise<void> {
  const db = admin.firestore();

  await db.collection("rateLimitViolations").add({
    userId,
    action,
    documentId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Rate limit violation: ${userId} - ${action}`);
}

/**
 * Rate limit for room creation
 */
export const rateLimitRoomCreation = functions.firestore
  .document("battleRooms/{roomCode}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const hostId = data.hostId;
    const roomCode = context.params.roomCode;

    if (!checkRateLimit(hostId, "roomCreation", LIMITS.roomCreation)) {
      console.log(`Rate limit exceeded for room creation: ${hostId}`);

      // Delete the room
      await snapshot.ref.delete();

      // Log violation
      await logViolation(hostId, "roomCreation", roomCode);
    }
  });

/**
 * Rate limit for room joining
 * Note: This monitors guest additions to rooms
 */
export const rateLimitRoomJoining = functions.firestore
  .document("battleRooms/{roomCode}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if a guest just joined
    if (!before.guestId && after.guestId) {
      const guestId = after.guestId;
      const roomCode = context.params.roomCode;

      if (!checkRateLimit(guestId, "roomJoining", LIMITS.roomJoining)) {
        console.log(`Rate limit exceeded for room joining: ${guestId}`);

        // Revert the guest addition
        await change.after.ref.update({
          guestId: null,
          players: before.players,
        });

        // Log violation
        await logViolation(guestId, "roomJoining", roomCode);
      }
    }
  });

/**
 * Combined rate limit function (export this for backward compatibility)
 */
export const rateLimit = {
  roomCreation: rateLimitRoomCreation,
  roomJoining: rateLimitRoomJoining,
};

// Cleanup old rate limit entries periodically (every 5 minutes)
setInterval(() => {
  const now = Date.now();
  for (const key in rateLimits) {
    if (now > rateLimits[key].resetTime) {
      delete rateLimits[key];
    }
  }
}, 5 * 60 * 1000);
