import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface GridConfig {
  rows: number;
  cols: number;
  mines: number;
}

// Grid configurations for each difficulty
const GRID_CONFIGS: { [key: string]: GridConfig } = {
  "beginner": { rows: 9, cols: 9, mines: 10 },
  "intermediate": { rows: 16, cols: 16, mines: 40 },
  "expert": { rows: 16, cols: 30, mines: 99 },
};

interface CellData {
  isMine: boolean;
  isRevealed: boolean;
  isFlagged: boolean;
  adjacentMines: number;
}

interface GridData {
  grid: CellData[][];
}

/**
 * Cloud Function to validate game outcomes when a battle finishes.
 * Prevents cheating by verifying the winner's grid data is valid.
 */
export const validateGameOutcome = functions.firestore
  .document("battleRooms/{roomCode}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const roomCode = context.params.roomCode;

    // Only validate when status changes to 'finished'
    if (before.status !== "finished" && after.status === "finished") {
      console.log(`Validating game outcome for room ${roomCode}`);

      const winnerId = after.winnerId;
      if (!winnerId) {
        console.log("No winner declared, skipping validation");
        return;
      }

      const winnerData = after.players[winnerId];
      if (!winnerData) {
        console.error("Winner data not found");
        await flagSuspiciousGame(roomCode, winnerId, "Winner data not found");
        return;
      }

      // Get grid data from private subcollection
      const gridDataDoc = await admin.firestore()
        .collection("battleRooms")
        .doc(roomCode)
        .collection("privateData")
        .doc(winnerId)
        .get();

      const gridDataString = gridDataDoc.exists ?
        gridDataDoc.data()?.gridData : winnerData.gridData;

      if (!gridDataString) {
        console.log("No grid data to validate");
        return;
      }

      try {
        const gridData: GridData = JSON.parse(gridDataString);
        const isValid = await validateWinnerGrid(
          gridData,
          after.difficulty,
          winnerData.revealedCells,
          winnerData.finishTime
        );

        if (!isValid) {
          await flagSuspiciousGame(
            roomCode,
            winnerId,
            "Invalid game outcome detected",
            {
              difficulty: after.difficulty,
              revealedCells: winnerData.revealedCells,
              finishTime: winnerData.finishTime,
            }
          );
        }
      } catch (error) {
        console.error("Error validating grid:", error);
        await flagSuspiciousGame(
          roomCode,
          winnerId,
          `Grid validation error: ${error}`
        );
      }
    }
  });

/**
 * Validates that the winner's grid is legitimate
 */
async function validateWinnerGrid(
  gridData: GridData,
  difficulty: string,
  revealedCells: number,
  finishTime: number
): Promise<boolean> {
  const config = GRID_CONFIGS[difficulty];
  if (!config) {
    console.error(`Unknown difficulty: ${difficulty}`);
    return false;
  }

  const grid = gridData.grid;

  // 1. Validate grid dimensions
  if (grid.length !== config.rows) {
    console.log(`Invalid rows: ${grid.length} vs ${config.rows}`);
    return false;
  }
  if (grid[0].length !== config.cols) {
    console.log(`Invalid cols: ${grid[0].length} vs ${config.cols}`);
    return false;
  }

  // 2. Count mines and revealed cells
  let mineCount = 0;
  let revealedCount = 0;
  let hitMine = false;

  for (let row = 0; row < grid.length; row++) {
    for (let col = 0; col < grid[row].length; col++) {
      const cell = grid[row][col];

      if (cell.isMine) {
        mineCount++;
        if (cell.isRevealed) {
          hitMine = true;
        }
      }

      if (cell.isRevealed && !cell.isMine) {
        revealedCount++;
      }
    }
  }

  // 3. Validate mine count
  if (mineCount !== config.mines) {
    console.log(`Invalid mine count: ${mineCount} vs ${config.mines}`);
    return false;
  }

  // 4. Winner shouldn't have hit a mine
  if (hitMine) {
    console.log("Winner hit a mine");
    return false;
  }

  // 5. Winner should have revealed all non-mine cells
  const totalNonMines = (config.rows * config.cols) - config.mines;
  if (revealedCount !== totalNonMines) {
    console.log(
      `Incomplete reveal: ${revealedCount} vs ${totalNonMines} expected`
    );
    return false;
  }

  // 6. Validate reported revealed cells matches actual
  if (revealedCells !== revealedCount) {
    console.log(
      `Revealed cells mismatch: reported ${revealedCells} vs actual ${revealedCount}`
    );
    return false;
  }

  // 7. Validate finish time is reasonable (at least 5 seconds)
  if (finishTime < 5) {
    console.log(`Suspiciously fast finish time: ${finishTime} seconds`);
    return false;
  }

  // 8. Validate finish time is not too long (max 24 hours)
  if (finishTime > 86400) {
    console.log(`Suspiciously long finish time: ${finishTime} seconds`);
    return false;
  }

  console.log("Grid validation passed");
  return true;
}

/**
 * Flags a suspicious game for review
 */
async function flagSuspiciousGame(
  roomCode: string,
  winnerId: string,
  reason: string,
  additionalData?: any
): Promise<void> {
  const db = admin.firestore();

  await db.collection("suspiciousGames").add({
    roomCode,
    winnerId,
    reason,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    additionalData: additionalData || null,
  });

  console.log(`Flagged suspicious game: ${roomCode} - ${reason}`);

  // Optionally: Auto-revert the win (uncomment to enable)
  // await db.collection('battleRooms').doc(roomCode).update({
  //   winnerId: null,
  //   status: 'finished',
  // });
}
