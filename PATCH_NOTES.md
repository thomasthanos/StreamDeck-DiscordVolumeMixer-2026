# Discord Volume Mixer 2.0.2 patch

## Connection and OAuth

- Parses Discord IPC frames incrementally and safely, including partial packets.
- Responds to IPC ping frames and reports Discord close codes instead of reducing every handshake failure to `ERR 8`.
- Uses the documented `http://localhost:1337/callback` URI during the OAuth code exchange.
- Adds network and command timeouts, atomic token-cache writes, stale-token recovery, and exponential reconnect backoff.
- Stops writing client secrets and OAuth tokens to diagnostic logs.

## Stability

- Prevents division/modulo-by-zero crashes when a channel is empty or a volume/page step is zero.
- Rejects voice controls while disconnected instead of leaving incorrect local state.
- Completes pending command callbacks on timeout/disconnect instead of leaking them.
- Clears stale speaking state when changing channels and accepts users first seen in an update event.
- Deduplicates avatar downloads and backs off failed downloads.

## Build

- Requires Qt 6.5 or newer and supports current Qt WebSocket APIs.
- Fails clearly when deployment tooling is missing or deployment fails.
- Package version is `2.0.2.1`.
- Shows `LOADING...` while a manual reconnect/authentication attempt is running.
