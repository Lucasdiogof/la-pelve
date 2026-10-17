# LAP-001: app stuck on the splash logo without internet

**Report (iPhone, airplane mode):** after force-closing and reopening, the app stays on the dark screen with only the centered logo. No error, no action. The screenshot proves the visual state, not the cause or the wait time.

## Where the logo can come from

The same logo (64 pt) is shown by two places, so the screenshot does not tell them apart:

1. `App` while the `bootstrap` future runs (`Supabase.initialize` + `initDependencies`). This path does no network call: `recoverSession()` runs un-awaited inside `Supabase.initialize` (supabase_flutter 2.17.1), so it cannot hold the splash.
2. `SessionDataGate` while the three critical resources (patients, agenda, financial) load for `/home`.

## Cause found in code (not reproduced on a device)

Path 2 had no upper bound:

- `ResourceCubit` awaited `fetch()` with no timeout, and the three critical `getAll()` repository calls had none either. A request that never settles (offline DNS/connect stalling, or `getSession()` waiting on an access-token refresh that retries) kept the gate in loading, with no error and no retry.
- When a request did fail, network exceptions were mapped to `UnexpectedFailure`, so the screen could not say it was a connection problem, and nothing retried when the network came back.

What is **not** proven: how long a real iPhone waits in this state and which request stalls. That needs observation on a device (see Pending).

## Changes

- `ResourceCubit`: 20 s limit per fetch (`fetchTimeout`), ending in `NetworkFailure`. Late responses are discarded by the existing generation guard.
- `core/error/network_errors.dart`: maps timeouts, `http.ClientException` (wraps socket/DNS errors) and `AuthRetryableFetchException` to `NetworkFailure`; used by the three critical repositories and by `signIn`.
- `SessionDataGate`: a network failure shows "No internet connection" with the session kept (pt/en/es), the retry button, and an automatic retry every 8 s while visible. Other failures keep the generic message. Nothing is signed out and no local data is erased.
- Sign-in without network now reports "No internet connection." instead of "Unexpected error."

There is no local data cache in the app, so offline the user sees the connection state, not clinical data. No clinical data is invented.

## Tests

`flutter analyze`: no issues. `flutter test`: 588 passed. New: fetch timeout, retry after timeout, DNS failure mapping, gate offline text, automatic recovery when the connection returns (loaded resources are not refetched), non-network failure keeps the generic text, error mapping.

## Scenarios

| | Result |
|---|---|
| A session + airplane mode | Gate ends in finite time (<= 20 s) with the offline state and retry. Pending on a real iPhone. |
| B no session + airplane mode | Login screen is public and has no remote call; sign-in reports no connection. Pending on a real iPhone. |
| C slow/DNS/timeouts | Ends in the offline state with retry (covered by unit/widget tests). |
| D online, then offline, reopen | Session is kept (no sign-out on network errors). Pending on a real iPhone. |
| E reconnect | Automatic retry loads only what is missing (widget test). Pending on a real iPhone. |
| F Android/web/iPhone | Not run. Pending real-device validation. |

## Pending

Reproduce before/after on an iPhone with airplane mode (record OS version, model, install mode) and confirm the wait time. Out of scope and untouched: WhatsApp/Meta, consents, Edge Functions, migrations.
