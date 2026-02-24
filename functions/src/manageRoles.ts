import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

/**
 * One-time bootstrap function to create the first admin user.
 * Can only be called once per email address to prevent abuse.
 *
 * Usage:
 *   firebase functions:call bootstrapFirstAdmin --data '{"email":"user@example.com"}'
 */
export const bootstrapFirstAdmin = functions.https.onCall(
  async (request) => {
    const { email } = request.data;

    if (!email || typeof email !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email is required"
      );
    }

    try {
      // Find user by email
      const userRecord = await admin.auth().getUserByEmail(email);
      const userId = userRecord.uid;

      // Check if user already has a role assigned (prevent re-bootstrapping)
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User document not found in Firestore"
        );
      }

      const userData = userDoc.data();
      if (userData?.role && userData.role !== "user") {
        throw new functions.https.HttpsError(
          "already-exists",
          `User already has role: ${userData.role}`
        );
      }

      // Grant admin role
      await admin.firestore().collection("users").doc(userId).update({
        role: "admin",
      });

      // Log the bootstrap action
      await admin.firestore().collection("auditLogs").add({
        type: "bootstrap_admin",
        userId: userId,
        email: email,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        action: "granted_admin_role",
        performedBy: "system",
      });

      return {
        success: true,
        message: `Admin role granted to ${email}`,
        userId: userId,
      };
    } catch (error: any) {
      console.error("Error bootstrapping admin:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to bootstrap admin: ${error.message}`
      );
    }
  }
);

/**
 * Grant dev or admin role to a user.
 * Only callable by existing admins.
 *
 * Usage:
 *   Call from client:
 *   const grantRole = httpsCallable(functions, 'grantDevRole');
 *   await grantRole({ userId: 'abc123', role: 'dev' });
 */
export const grantDevRole = functions.https.onCall(async (request) => {
  const { userId, role } = request.data;

  // Verify caller is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated to grant roles"
    );
  }

  // Verify caller is an admin
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();

  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can grant roles"
    );
  }

  // Validate input
  if (!userId || typeof userId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid userId is required"
    );
  }

  if (!role || !["user", "dev", "admin"].includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Role must be 'user', 'dev', or 'admin'"
    );
  }

  try {
    // Verify target user exists
    const targetUserDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!targetUserDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    // Update user role
    await admin.firestore().collection("users").doc(userId).update({
      role: role,
    });

    // Log the role change
    await admin.firestore().collection("auditLogs").add({
      type: "role_change",
      targetUserId: userId,
      newRole: role,
      oldRole: targetUserDoc.data()?.role || "user",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      performedBy: request.auth.uid,
      performedByEmail: request.auth.token.email || "unknown",
    });

    return {
      success: true,
      message: `Role '${role}' granted to user ${userId}`,
    };
  } catch (error: any) {
    console.error("Error granting role:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to grant role: ${error.message}`
    );
  }
});
