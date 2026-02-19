import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import and export Cloud Functions
export { validateGameOutcome } from "./validateGameOutcome";
export { rateLimitRoomCreation, rateLimitRoomJoining } from "./rateLimit";
export { cleanupExpiredRooms } from "./cleanupExpiredRooms";
export { auditBattleWinner, auditUserStats, auditRapidRoomCreation } from "./auditLog";
export { bootstrapFirstAdmin, grantDevRole } from "./manageRoles";
export { migrateQualifierSystem } from "./migration";
export { updateEloRatings } from "./updateEloRatings";
