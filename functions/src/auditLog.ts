import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Creates an audit log entry
 */
async function createAuditLog(
  userId: string,
  action: string,
  resourceType: string,
  resourceId: string,
  before: any,
  after: any,
  metadata?: any
): Promise<void> {
  const db = admin.firestore();

  await db.collection("auditLogs").add({
    userId,
    action,
    resourceType,
    resourceId,
    before,
    after,
    metadata: metadata || null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Audit log created: ${action} by ${userId} on ${resourceType}/${resourceId}`);
}

/**
 * Audit log for battle room winner changes
 */
export const auditBattleWinner = functions.firestore
  .document("battleRooms/{roomCode}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const roomCode = context.params.roomCode;

    // Log winner changes
    if (before.winnerId !== after.winnerId && after.winnerId) {
      await createAuditLog(
        after.winnerId,
        "battle_won",
        "battleRooms",
        roomCode,
        { winnerId: before.winnerId },
        { winnerId: after.winnerId },
        {
          difficulty: after.difficulty,
          hostId: after.hostId,
          guestId: after.guestId,
        }
      );
    }
  });

/**
 * Audit log for user stats changes (XP, Elo, wins/losses)
 */
export const auditUserStats = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    const beforeStats = before.stats || {};
    const afterStats = after.stats || {};

    // Check for large XP adjustments (more than 100 at once)
    if (afterStats.xp && beforeStats.xp) {
      const xpDiff = Math.abs(afterStats.xp - beforeStats.xp);
      if (xpDiff > 100) {
        await createAuditLog(
          userId,
          "large_xp_change",
          "users",
          userId,
          { xp: beforeStats.xp },
          { xp: afterStats.xp },
          { difference: xpDiff }
        );
      }
    }

    // Check for large Elo adjustments (more than 100 at once)
    if (afterStats.eloRating && beforeStats.eloRating) {
      const eloDiff = Math.abs(afterStats.eloRating - beforeStats.eloRating);
      if (eloDiff > 100) {
        await createAuditLog(
          userId,
          "large_elo_change",
          "users",
          userId,
          { eloRating: beforeStats.eloRating },
          { eloRating: afterStats.eloRating },
          { difference: eloDiff }
        );
      }
    }

    // Check for stat decreases (should never happen with monotonic stats)
    const statsToCheck = ["gamesPlayed", "gamesWon", "battleWins", "battleLosses"];

    for (const stat of statsToCheck) {
      if (afterStats[stat] < beforeStats[stat]) {
        await createAuditLog(
          userId,
          "stat_decreased",
          "users",
          userId,
          { [stat]: beforeStats[stat] },
          { [stat]: afterStats[stat] },
          { stat }
        );
      }
    }
  });

/**
 * Audit log for rapid room creation by same user
 */
export const auditRapidRoomCreation = functions.firestore
  .document("battleRooms/{roomCode}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const hostId = data.hostId;
    const roomCode = context.params.roomCode;

    // Query recent rooms created by this user (last 5 minutes)
    const db = admin.firestore();
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    const recentRooms = await db
      .collection("battleRooms")
      .where("hostId", "==", hostId)
      .where("createdAt", ">", fiveMinutesAgo)
      .get();

    // If more than 10 rooms in 5 minutes, log it
    if (recentRooms.size > 10) {
      await createAuditLog(
        hostId,
        "rapid_room_creation",
        "battleRooms",
        roomCode,
        null,
        { roomCode },
        { recentRoomCount: recentRooms.size }
      );
    }
  });

/**
 * Combined audit log function (export this for use in index.ts)
 */
export const auditLog = {
  battleWinner: auditBattleWinner,
  userStats: auditUserStats,
  rapidRoomCreation: auditRapidRoomCreation,
};
