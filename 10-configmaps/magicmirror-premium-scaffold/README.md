# MagicMirror Premium — Full Scaffold

Contents:
- `helm-magicmirror/` — Helm chart (Longhorn PVC, Traefik Ingress+TLS, Scrypted HLS, Spotify, theme)
- `values.example.yaml` — starting point for your config
- `scripts/` — helper scripts (auth URL, token exchange, deploy, uninstall)
- `extras/sftp-helper.yaml` — optional SFTP server bound to the Longhorn PVC
- `extras/node-red-flow.json` — tiny flow to dim/toggle based on presence

## Quick start

```bash
unzip magicmirror-premium-scaffold.zip
cd magicmirror-premium-scaffold

# 1) Fill in values
cp values.example.yaml helm-magicmirror/values.yaml
vim helm-magicmirror/values.yaml

# 2) Install
./scripts/deploy.sh ./helm-magicmirror suite
```

## Spotify OAuth
- Redirect URI: `https://mirror.suite.home.arpa/spotify/callback` (helper is included; toggle in values)
- Build URL: `./scripts/spotify_auth_url.sh`
- Exchange tokens: `./scripts/spotify_exchange.sh <CLIENT_ID> <CLIENT_SECRET> <CODE>`
- Put `accessToken` & `refreshToken` in `helm-magicmirror/values.yaml`

## Optional: SFTP (content drop to /data)
```bash
kubectl apply -f extras/sftp-helper.yaml
# then SFTP to Service from your LAN or via 'kubectl port-forward'
```

## Scale & HPA
Set `replicaCount` to 2 in values and enable the HPA block once stable.
