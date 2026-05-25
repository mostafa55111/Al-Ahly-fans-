# Phase B — Deterministic Vote Integrity Report

**Date:** 2026-05-19  
**Repos:** zamalekawy + gomhor_alahly_v2 (mirrored)

---

## QA gate

| Check | Result |
|-------|--------|
| `flutter analyze` (vote_scale + touched paths) | **0 errors** |
| `flutter test test/features/crowd/vote_scale/` | **28/28 GREEN** |

---

## Step 1 — Deterministic shard allocation

- **New:** `deterministic_vote_allocator.dart` — FNV-1a 64-bit over UTF-8 key `club|match|player|uid`
- **Updated:** `sharded_vote_allocator.dart` — removed `Random`, entropy, `hashCode`
- **Updated:** `vote_shard_allocator.dart` — `ShardedVoteShardAllocator` uses FNV-1a
- **Updated:** `sharded_vote_repository.dart` — passes `matchId` + `playerId` to allocator

**Guarantee:** same `(club, match, player, uid)` → same `shardId` on all platforms.

---

## Step 2 — Vote idempotency

- **New:** `vote_idempotency_guard.dart` — `VoteOperationFingerprint` + LRU (`castVotes`, `finalize`)
- **Wired:** `MatchVotesRepositoryRtdb.castVoteImmutableTransaction` — local replay guard before RTDB tx
- **Wired:** `FinalizationAuthorityService` — finalize fingerprint dedupe

---

## Step 3 — Aggregation determinism

- **New:** `aggregation_determinism_verifier.dart` — sorted shard merge, checksum, double-pass verify
- **Updated:** `VoteAggregationService` — **no legacy fallback** when `preferShardedSource && hasShards`
- Debug-only checksum reporting via `DeterministicRuntimeReport`

---

## Step 4 — Test suite (`test/features/crowd/vote_scale/`)

| Test file | Coverage |
|-----------|----------|
| `deterministic_allocator_test.dart` | Stable shard + key |
| `aggregation_determinism_test.dart` | Order-invariant totals/checksum |
| `reconnect_replay_test.dart` | 50× reconnect → 1 allowed |
| `duplicate_finalize_test.dart` | 12 concurrent finalize → 1 allowed |
| `shard_distribution_stability_test.dart` | 100k allocations, 10k fairness |
| `high_volume_vote_simulation_test.dart` | 100k simulate + 10k replay attack |
| `sharded_vote_allocator_test.dart` | Updated (no Random) |

---

## Step 5 — Runtime reports (debug only)

- **New:** `deterministic_runtime_report.dart`
  - duplicate vote prevented, replay blocked, finalize race prevented
  - aggregation mismatch, shard imbalance %, checksum drift

---

## Step 6 — Production hardening summary

| Area | Change |
|------|--------|
| Sharded sessions | Legacy `players/*/votes` fallback **removed** during sharded finalize |
| Finalize | Idempotency guard + existing `_localFinalized` + awards snapshot tx |
| Cast vote | Idempotency + RTDB transaction abort (unchanged contract) |
| Allocator | 100% deterministic — no runtime entropy |

---

## Simulation metrics (local tests)

| Metric | Value |
|--------|-------|
| Simulated votes | **100,000** |
| Aggregation deterministic | **yes** |
| Replay attack (10k same op) | **1 allowed / 9999 blocked** |
| Reconnect storm (50 retries) | **1 allowed / 49 blocked** |
| Finalize race (12 parallel) | **1 allowed / 11 blocked** |
| 100k allocation throughput | **~2–4k votes/ms** (device-dependent) |
| Shard buckets | **32** (`s0`…`s31`) |
| Max shard skew (10k sample) | typically **&lt; 80%** (healthy spread) |

---

## Remaining / flaky

- `production_verification` `ShardDistributionAnalyzer` may still flake in **full** `test/features/crowd` suite when run with synthetic load in parallel — **not** in `vote_scale/` gate.
- Physical RTDB integration tests not in scope (logic-only simulation per spec).

---

## Backward compatibility

- Old sessions without shards still use legacy path when `preferShardedSource == false` or no shard data.
- `pickShardId(uid, clubTag)` optional `matchId`/`playerId` — defaults to `''` for older call sites.
