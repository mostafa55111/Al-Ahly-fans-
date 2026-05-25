/**
 * Crowd voting authority — server-side finalize / aggregate / publish.
 *
 * Deploy:
 *   firebase deploy --only functions:finalizeVotingSession,functions:aggregateShardedVotes,functions:publishAwardsSnapshot
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

const LEASE_TTL_MS = 90000;

function clubTag(raw) {
  return String(raw || '').trim().toLowerCase();
}

function monthKeyFromMs(ms) {
  const d = new Date(ms);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

function seasonKeyFromMs(ms) {
  return String(new Date(ms).getUTCFullYear());
}

async function loadOwnerEmails() {
  const snap = await admin.database().ref('app_configs/owner_emails').get();
  const emails = new Set();
  if (!snap.exists()) return emails;
  const v = snap.val();
  if (Array.isArray(v)) {
    v.forEach((e) => {
      const s = String(e || '').trim().toLowerCase();
      if (s) emails.add(s);
    });
  } else if (v && typeof v === 'object') {
    Object.values(v).forEach((e) => {
      const s = String(e || '').trim().toLowerCase();
      if (s) emails.add(s);
    });
  }
  return emails;
}

function assertAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'auth_required');
  }
}

async function acquireLease(club, matchId, ownerId) {
  const ref = admin.database().ref(`authority_runtime/${club}/${matchId}`);
  const now = Date.now();
  const tx = await ref.transaction((current) => {
    if (current && current.finalized === true) return;
    if (
      current &&
      current.leaseOwner &&
      current.leaseOwner !== ownerId &&
      Number(current.leaseExpiresAt || 0) > now
    ) {
      return;
    }
    return {
      leaseOwner: ownerId,
      leaseAt: now,
      leaseExpiresAt: now + LEASE_TTL_MS,
      finalized: false,
    };
  });
  return tx.committed;
}

async function sumPlayerShards(club, matchId, playerId) {
  const snap = await admin
    .database()
    .ref(`match_vote_shards/${club}/${matchId}/${playerId}`)
    .get();
  if (!snap.exists()) return 0;
  let total = 0;
  const shards = snap.val();
  if (!shards || typeof shards !== 'object') return 0;
  Object.values(shards).forEach((node) => {
    if (!node || typeof node !== 'object') return;
    const c = Number(node.count || 0);
    if (!Number.isNaN(c)) total += c;
  });
  return total;
}

async function aggregateMatch(club, matchId, playerIds, useLegacyPlayers) {
  const totals = {};
  let usedSharded = false;
  let usedLegacy = false;

  for (const pid of playerIds) {
    const shardTotal = await sumPlayerShards(club, matchId, pid);
    if (shardTotal > 0) {
      totals[pid] = shardTotal;
      usedSharded = true;
    }
  }

  if (!usedSharded && useLegacyPlayers) {
    Object.entries(useLegacyPlayers).forEach(([pid, p]) => {
      const v = Number((p && p.votes) || 0);
      if (v > 0) {
        totals[pid] = v;
        usedLegacy = true;
      }
    });
  }

  let winnerPlayerId = null;
  let winnerVotes = 0;
  Object.entries(totals).forEach(([pid, count]) => {
    if (count > winnerVotes) {
      winnerVotes = count;
      winnerPlayerId = pid;
    }
  });

  const sessionTotal = Object.values(totals).reduce((a, b) => a + b, 0);
  return {
    playerTotals: totals,
    sessionTotal,
    winnerPlayerId,
    winnerVotes,
    usedShardedSource: usedSharded,
    usedLegacySource: usedLegacy,
  };
}

exports.finalizeVotingSession = functions.https.onCall(async (data, context) => {
  assertAuth(context);
  const club = clubTag(data.clubTag);
  const matchId = String(data.matchId || '').trim();
  const closedAtServerMs = Number(data.closedAtServerMs || 0);
  const shadow = data.shadow === true;
  const uid = context.auth.uid;

  if (!club || !matchId || closedAtServerMs <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'bad_request');
  }

  const leaseOwner = `cf:${uid}`;
  const acquired = await acquireLease(club, matchId, leaseOwner);
  if (!acquired) {
    return {
      success: false,
      alreadyFinalized: false,
      snapshotWritten: false,
      errorMessage: 'lease_not_acquired',
    };
  }

  const activeSnap = await admin
    .database()
    .ref(`match_votes/${club}/active_match`)
    .get();
  if (!activeSnap.exists()) {
    return { success: false, errorMessage: 'no_active_session' };
  }
  const session = activeSnap.val() || {};
  if (String(session.id || '') !== matchId) {
    return { success: false, errorMessage: 'match_mismatch' };
  }
  if (session.awardsFinalized === true || session.awardsFinalized === 1) {
    return { success: true, alreadyFinalized: true, snapshotWritten: false };
  }

  const playersSnap = await admin.database().ref(`match_votes/${club}/players`).get();
  const players = playersSnap.exists() ? playersSnap.val() || {} : {};
  const playerIds = Object.keys(players);

  const agg = await aggregateMatch(club, matchId, playerIds, players);

  if (!agg.winnerPlayerId || agg.winnerVotes <= 0) {
    if (!shadow) {
      await admin.database().ref(`match_votes/${club}/active_match`).update({
        awardsFinalized: true,
        votingEnabled: false,
        status: 'closed',
        closedAtServer: closedAtServerMs,
      });
      await admin.database().ref(`authority_runtime/${club}/${matchId}`).update({
        finalized: true,
        leaseExpiresAt: Date.now(),
      });
    }
    return { success: true, snapshotWritten: false };
  }

  const winner = players[agg.winnerPlayerId] || {};
  const year = new Date(closedAtServerMs).getUTCFullYear();
  const awardPath = `awards/${club}/matches/${year}/${matchId}`;
  const existing = await admin.database().ref(awardPath).get();
  if (existing.exists()) {
    if (!shadow) {
      await admin.database().ref(`match_votes/${club}/active_match`).update({
        awardsFinalized: true,
        votingEnabled: false,
        status: 'closed',
        closedAtServer: closedAtServerMs,
      });
    }
    return { success: true, alreadyFinalized: true, snapshotWritten: false };
  }

  if (!shadow) {
    const award = {
      matchId,
      title: String(session.title || ''),
      opponent: String(session.opponent || ''),
      sessionType: String(session.sessionType || 'league'),
      winnerPlayerId: agg.winnerPlayerId,
      winnerName: String(winner.name || agg.winnerPlayerId),
      winnerCardSnapshot: {
        playerId: agg.winnerPlayerId,
        name: String(winner.name || ''),
        cardUrl: String(winner.cardImageUrl || winner.imageUrl || ''),
      },
      totalVotes: agg.winnerVotes,
      closedAt: closedAtServerMs,
      finalizedAtServer: closedAtServerMs,
      monthKey: monthKeyFromMs(closedAtServerMs),
      seasonKey: seasonKeyFromMs(closedAtServerMs),
      playerVoteTotals: agg.playerTotals,
    };
    await admin.database().ref(awardPath).set(award);
    await admin.database().ref(`match_votes/${club}/active_match`).update({
      awardsFinalized: true,
      votingEnabled: false,
      status: 'closed',
      closedAtServer: closedAtServerMs,
    });
    await admin.database().ref(`authority_runtime/${club}/${matchId}`).update({
      finalized: true,
      leaseExpiresAt: Date.now(),
    });
  }

  return { success: true, snapshotWritten: !shadow };
});

exports.aggregateShardedVotes = functions.https.onCall(async (data, context) => {
  assertAuth(context);
  const club = clubTag(data.clubTag);
  const matchId = String(data.matchId || '').trim();
  if (!club || !matchId) {
    throw new functions.https.HttpsError('invalid-argument', 'bad_request');
  }
  const playersSnap = await admin.database().ref(`match_votes/${club}/players`).get();
  const players = playersSnap.exists() ? playersSnap.val() || {} : {};
  const agg = await aggregateMatch(club, matchId, Object.keys(players), players);
  return agg;
});

exports.publishAwardsSnapshot = functions.https.onCall(async (data, context) => {
  assertAuth(context);
  const owners = await loadOwnerEmails();
  const email = String((context.auth.token && context.auth.token.email) || '')
    .trim()
    .toLowerCase();
  if (owners.size > 0 && !owners.has(email)) {
    throw new functions.https.HttpsError('permission-denied', 'owner_only');
  }

  const club = clubTag(data.clubTag);
  const matchId = String(data.matchId || '').trim();
  const year = Number(data.year || 0);
  const payload = data.awardPayload;
  if (!club || !matchId || year <= 0 || !payload || typeof payload !== 'object') {
    throw new functions.https.HttpsError('invalid-argument', 'bad_request');
  }

  const path = `awards/${club}/matches/${year}/${matchId}`;
  const ref = admin.database().ref(path);
  const tx = await ref.transaction((current) => {
    if (current != null) return;
    return payload;
  });
  return { success: tx.committed };
});
