# MagicMirror Premium — Full Scaffold (v2)

- HPA enabled by default (2→4 replicas)
- OAuth helper ingress has high Traefik priority to fix 'Cannot GET /spotify/callback'
- Spotify Client ID prefilled with your provided value
- Optional SMB helper bound to Longhorn PVC for drag-and-drop

## Quick start
```bash
unzip magicmirror-premium-scaffold-v2.zip
cd magicmirror-premium-scaffold-v2
cp values.example.yaml helm-magicmirror/values.yaml
vim helm-magicmirror/values.yaml
./scripts/deploy.sh ./helm-magicmirror suite
```

## Spotify OAuth
- Redirect URI: `https://mirror.suite.home.arpa/spotify/callback`
- If you saw `Cannot GET /spotify/callback`, we now set `router.priority: 100` on the callback Ingress so Traefik sends that path to the helper, not MagicMirror.

## SMB helper
```bash
kubectl apply -f extras/smb-helper.yaml
# On your laptop: connect to \\mirror-content-smb.suite.svc.cluster.local\mirror (or port-forward 445)
# User: wayne  Pass: changeme  (PLEASE change in YAML)
```

## Scale
HPA is on by default. Tune targets in `values.yaml`.
