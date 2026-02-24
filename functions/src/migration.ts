import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

/**
 * One-time migration function to:
 * 1. Create the /appConfig/ranked document with default qualifier count
 * 2. Update all existing users to set isInQualifiers: false and role: 'user'
 *
 * This should only be run once during the initial deployment of the
 * qualifier system.
 *
 * Usage (from Firebase console or CLI):
 *   firebase functions:call migrateQualifierSystem
 *
 * Returns statistics about what was migrated.
 */
export const migrateQualifierSystem = functions.https.onCall(
  async (request) => {
    // Only allow admins to run migration (or run from console with admin SDK)
    if (request.auth) {
      const callerDoc = await admin
        .firestore()
        .collection("users")
        .doc(request.auth.uid)
        .get();

      if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins can run migrations"
        );
      }
    }

    const stats = {
      configCreated: false,
      usersUpdated: 0,
      errors: [] as string[],
    };

    try {
      // 1. Create /appConfig/ranked document
      const configRef = admin.firestore().collection("appConfig").doc("ranked");
      const configDoc = await configRef.get();

      if (!configDoc.exists) {
        await configRef.set({
          qualifierMatchCount: 3,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedBy: "migration_system",
        });
        stats.configCreated = true;
        console.log("Created appConfig/ranked document");
      } else {
        console.log("appConfig/ranked document already exists, skipping");
      }

      // 2. Update all existing users
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

      console.log(`Found ${usersSnapshot.size} users to migrate`);

      // Use batched writes (max 500 per batch)
      const batches: admin.firestore.WriteBatch[] = [];
      let currentBatch = admin.firestore().batch();
      let operationsInBatch = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();

        // Prepare updates
        const updates: any = {};

        // Set role to 'user' if not already set
        if (!userData.role) {
          updates.role = "user";
        }

        // Set isInQualifiers to false for existing users (they're already ranked)
        if (
          userData.stats &&
          typeof userData.stats.isInQualifiers === "undefined"
        ) {
          updates["stats.isInQualifiers"] = false;
        }

        // Only update if there are changes needed
        if (Object.keys(updates).length > 0) {
          currentBatch.update(userDoc.ref, updates);
          operationsInBatch++;

          // Create new batch if current is full
          if (operationsInBatch >= 500) {
            batches.push(currentBatch);
            currentBatch = admin.firestore().batch();
            operationsInBatch = 0;
          }
        }
      }

      // Add remaining batch if it has operations
      if (operationsInBatch > 0) {
        batches.push(currentBatch);
      }

      // Commit all batches
      for (let i = 0; i < batches.length; i++) {
        try {
          await batches[i].commit();
          console.log(`Committed batch ${i + 1}/${batches.length}`);
        } catch (error: any) {
          const errorMsg = `Error committing batch ${i + 1}: ${error.message}`;
          console.error(errorMsg);
          stats.errors.push(errorMsg);
        }
      }

      stats.usersUpdated = batches.length * 500; // Approximate

      // Log migration completion
      await admin.firestore().collection("auditLogs").add({
        type: "migration",
        name: "qualifier_system_migration",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        performedBy: request.auth?.uid || "system",
        stats: stats,
      });

      return {
        success: true,
        message: "Migration completed successfully",
        stats: stats,
      };
    } catch (error: any) {
      console.error("Migration error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Migration failed: ${error.message}`
      );
    }
  }
);
