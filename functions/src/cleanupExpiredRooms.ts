import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Scheduled Cloud Function to cleanup expired battle rooms.
 * Runs daily at midnight UTC to delete rooms older than 24 hours.
 *
 * Note: Requires Cloud Scheduler to be enabled in your GCP project.
 * Deploy with: firebase deploy --only functions:cleanupExpiredRooms
 * Schedule: every day at 00:00 UTC
 */
export const cleanupExpiredRooms = functions.pubsub
  .schedule("0 0 * * *") // Runs at midnight UTC every day
  .timeZone("UTC")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const cutoffTime = new Date(now.toDate().getTime() - 24 * 60 * 60 * 1000); // 24 hours ago

    console.log(`Starting cleanup of rooms created before ${cutoffTime.toISOString()}`);

    try {
      // Query rooms older than 24 hours
      const expiredRoomsSnapshot = await db
        .collection("battleRooms")
        .where("createdAt", "<", cutoffTime)
        .get();

      if (expiredRoomsSnapshot.empty) {
        console.log("No expired rooms found");
        return null;
      }

      console.log(`Found ${expiredRoomsSnapshot.size} expired rooms to delete`);

      // Batch delete rooms
      const batchSize = 500; // Firestore batch limit
      let deletedCount = 0;

      for (let i = 0; i < expiredRoomsSnapshot.docs.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = expiredRoomsSnapshot.docs.slice(i, i + batchSize);

        for (const doc of batchDocs) {
          batch.delete(doc.ref);

          // Also delete private data subcollection
          const privateDataSnapshot = await doc.ref
            .collection("privateData")
            .get();

          for (const privateDoc of privateDataSnapshot.docs) {
            batch.delete(privateDoc.ref);
          }
        }

        await batch.commit();
        deletedCount += batchDocs.length;
        console.log(`Deleted batch of ${batchDocs.length} rooms`);
      }

      console.log(`Cleanup completed: ${deletedCount} rooms deleted`);
      return null;
    } catch (error) {
      console.error("Error during room cleanup:", error);
      throw error;
    }
  });
