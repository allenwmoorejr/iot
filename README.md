# hb-suite rebuild kit

Apply in order:

```bash
kubectl apply -f 00-namespace/
kubectl apply -f 10-configmaps/
kubectl apply -f 20-storage/
kubectl apply -f 30-apps/
kubectl apply -f 40-ingress/
kubectl apply -f 50-ops/
```

Then:
- Put your OpenWeather key in `10-configmaps/secret-openweather.yaml` before applying.
- Ensure MetalLB advertises 192.168.50.242 (Traefik) and 192.168.50.245 (Pi-hole).
- Make Pi-hole the LAN resolver; records for `*.suite.home.arpa` point to 192.168.50.242.

Backups:
- Run `kubectl -n suite create job --from=cronjob/homebridge-backup homebridge-backup-now` or apply `50-ops/homebridge-backup-now-job.yaml`.
- Restore with `kubectl apply -f 50-ops/homebridge-restore-job.yaml` (expects `homebridge-*.tgz` in PVC `homebridge-backups`).

Notes:
- NodeSelectors mirror your layout (w0: devices & MQTT; m2: pihole, zigbee2mqtt; m3: magicmirror; w2: wyze).
- If Traefik CRDs aren't installed, apply Traefik first or remove Middleware annotations temporarily.
