# Runtime Ownership Matrix — Phase D

| Responsibility | Owner | Fallback owner |
|----------------|-------|----------------|
| Production finalize (lease → award → claim) | `ProductionFinalizePipeline` | — |
| Authority mode (local / remote / hybrid) | `AuthorityOrchestrator` | `SafeRollbackCoordinator` → local |
| Local RTDB finalize steps | `FinalizationAuthorityService` via `LocalAuthorityGateway` | Remote CF once, then local |
| Transient finalize retries | `FinalizeRetryCoordinator` (inside pipeline when `enableRetry`) | `CrowdRecoveryQueue` + pipeline replay |
| Dead session recovery | `DeadSessionRecoveryService` → pipeline | Queued `replay` tasks |
| Session close detection | `VotingSessionLifecycleService.notifyActiveSession` | Recovery on pipeline failure |
| Fan session/players streams | `MatchVotingCubit` | Phased restore via `LazyVoteSubscriptionController` |
| Reconnect backoff | `ReconnectBackoffController` | `InfrastructureDegradationResolver` lightweight mode |
| Vote write idempotency | `VoteIdempotencyGuard` + transaction paths | `DurableVoteIntentQueue` |
| Degradation mode | `InfrastructureDegradationResolver` | `RuntimePolicyMatrix` (read-only policy) |
| Ops / sandbox | `ProductionSurfaceGate` | Disabled in release |
| Stream leak audit | `StreamLifecycleAudit` | debug only |

## Eliminated duplicate ownership (Phase D)

- Lifecycle no longer calls `AuthorityOrchestrator` directly
- Recovery no longer owns separate lease+orchestrator path
- Removed parallel `finalizationAuthority` branch in lifecycle (orchestrator-only via pipeline)
