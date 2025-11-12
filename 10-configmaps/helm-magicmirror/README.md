# MagicMirror Premium (Helm)

This chart deploys a premium MagicMirror setup with:
- Longhorn PVC (RWX) mounted at `/data`
- Traefik Ingress + TLS
- Live camera via Scrypted (HLS) or snapshot
- Spotify "Now Playing" module
- Luxe theme and curated layout

## Install

```bash
helm upgrade --install magicmirror /path/to/helm-magicmirror \
  --namespace suite --create-namespace
```

Edit `values.yaml` first (hostnames, OWM key, ICS, Scrypted URL, Spotify creds).

## Spotify Access & Refresh Tokens

1. Create an app at https://developer.spotify.com/dashboard
   - Add Redirect URI: `http://localhost:8888/callback`
2. Get an authorization code:
   ```bash
   CLIENT_ID=...
   REDIRECT_URI=http://localhost:8888/callback
   SCOPE="user-read-playback-state user-read-currently-playing"
   echo "Open this URL in a browser:"
   echo "https://accounts.spotify.com/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=${REDIRECT_URI}&scope=${SCOPE// /%20}"
   ```
   After login, copy the `?code=...` from the redirected URL.
3. Exchange code for tokens:
   ```bash
   CLIENT_ID=...
   CLIENT_SECRET=...
   CODE="paste-code-here"
   REDIRECT_URI=http://localhost:8888/callback
   curl -s -X POST "https://accounts.spotify.com/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -u "${CLIENT_ID}:${CLIENT_SECRET}" \
     -d "grant_type=authorization_code&code=${CODE}&redirect_uri=${REDIRECT_URI}"
   ```
   This returns `access_token` and `refresh_token`.
4. Put both into `values.yaml` under `.spotify.accessToken` and `.spotify.refreshToken`,
   or set them as Secrets after install:
   ```bash
   kubectl -n suite create secret generic spotify-credentials --from-literal=clientId=$CLIENT_ID \
     --from-literal=clientSecret=$CLIENT_SECRET --from-literal=accessToken=$ACCESS --from-literal=refreshToken=$REFRESH \
     --dry-run=client -o yaml | kubectl apply -f -
   kubectl -n suite rollout restart deploy/magicmirror-server
   ```

## Notes

- If using RWX with Longhorn, leave `replicaCount: 1` until you're happy, then scale to 2+ and enable HPA.
- NetworkPolicy is included to allow Traefik → 8080 only.
- The chart clones extra modules (MMM-NowPlayingOnSpotify, MMM-RTSPStream) via init containers.
- Customize `/data/custom.css` at runtime; it's on the Longhorn PVC.
