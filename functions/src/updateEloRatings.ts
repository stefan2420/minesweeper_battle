import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

function calculateExpectedScore(ratingA: number, ratingB: number): number {
  return 1.0 / (1.0 + Math.pow(10, (ratingB - ratingA) / 400.0));
}

function getKFactor(rankedGamesPlayed: number, rating: number): number {
  if (rankedGamesPlayed < 20) return 40;
  if (rating >= 1800) return 16;
  return 24;
}

function applyRatingFloor(rating: number): number {
  return Math.max(100, rating);
}

export const updateEloRatings = functions.firestore
  .document("battleRooms/{roomCode}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger when status transitions to 'finished'
    if (before.status === "finished" || after.status !== "finished") {
      return null;
    }

    const winnerId: string | undefined = after.winnerId;
    if (!winnerId) {
      // Draw — no ELO change
      return null;
    }

    const hostId: string = after.hostId;
    const guestId: string = after.guestId;

    if (!hostId || !guestId) return null;

    const loserId = winnerId === hostId ? guestId : hostId;

    // Fetch both users
    const [winnerDoc, loserDoc] = await Promise.all([
      db.collection("users").doc(winnerId).get(),
      db.collection("users").doc(loserId).get(),
    ]);

    if (!winnerDoc.exists || !loserDoc.exists) return null;

    const winnerData = winnerDoc.data()!;
    const loserData = loserDoc.data()!;

    const winnerStats = winnerData.stats ?? {};
    const loserStats = loserData.stats ?? {};

    const winnerRating: number = winnerStats.eloRating ?? 1200;
    const loserRating: number = loserStats.eloRating ?? 1200;
    const winnerGames: number = winnerStats.rankedGamesPlayed ?? 0;
    const loserGames: number = loserStats.rankedGamesPlayed ?? 0;
    const winnerPeak: number = winnerStats.peakEloRating ?? 1200;
    const winnerInQualifiers: boolean = winnerStats.isInQualifiers ?? false;
    const loserInQualifiers: boolean = loserStats.isInQualifiers ?? false;

    const winnerExpected = calculateExpectedScore(winnerRating, loserRating);
    const loserExpected = calculateExpectedScore(loserRating, winnerRating);

    const winnerK = getKFactor(winnerGames, winnerRating);
    const loserK = getKFactor(loserGames, loserRating);

    const winnerNewRating = applyRatingFloor(
      Math.round(winnerRating + winnerK * (1.0 - winnerExpected))
    );
    const loserNewRating = applyRatingFloor(
      Math.round(loserRating + loserK * (0.0 - loserExpected))
    );
    const winnerNewPeak = Math.max(winnerNewRating, winnerPeak);

    // Read qualifier threshold from appConfig
    const configDoc = await db.collection("appConfig").doc("ranked").get();
    const qualifierThreshold: number = configDoc.exists
      ? (configDoc.data()!.qualifierMatchCount ?? 5)
      : 5;

    const winnerCompletesQualifiers =
      winnerInQualifiers && winnerGames + 1 >= qualifierThreshold;
    const loserCompletesQualifiers =
      loserInQualifiers && loserGames + 1 >= qualifierThreshold;

    const batch = db.batch();

    const winnerUpdates: Record<string, unknown> = {
      "stats.eloRating": winnerNewRating,
      "stats.peakEloRating": winnerNewPeak,
      "stats.rankedGamesPlayed": admin.firestore.FieldValue.increment(1),
    };
    if (winnerCompletesQualifiers) {
      winnerUpdates["stats.isInQualifiers"] = false;
    }
    batch.update(db.collection("users").doc(winnerId), winnerUpdates);

    const loserUpdates: Record<string, unknown> = {
      "stats.eloRating": loserNewRating,
      "stats.rankedGamesPlayed": admin.firestore.FieldValue.increment(1),
    };
    if (loserCompletesQualifiers) {
      loserUpdates["stats.isInQualifiers"] = false;
    }
    batch.update(db.collection("users").doc(loserId), loserUpdates);

    await batch.commit();

    functions.logger.info(
      `ELO updated: winner ${winnerId} ${winnerRating}→${winnerNewRating}, ` +
        `loser ${loserId} ${loserRating}→${loserNewRating}`
    );

    return null;
  });
