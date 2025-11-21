NS ?= suite
HB_DEP ?= homebridge
HB_HOST ?= homebridge.suite.home.arpa
INGRESS_VIP ?= 192.168.50.242

hb-dehostnet:
	kubectl -n $(NS) patch deploy/$(HB_DEP) --type=json -p='[{"op":"remove","path":"/spec/template/spec/hostNetwork"},{"op":"remove","path":"/spec/template/spec/dnsPolicy"},{"op":"remove","path":"/spec/template/spec/hostname"}]' || true
	kubectl -n $(NS) patch deploy/$(HB_DEP) --type=merge -p='$(shell printf "%s" "\
spec: \
  template: \
    spec: \
      containers: \
      - name: $(HB_DEP) \
        env: \
        - { name: HOMEBRIDGE_CONFIG_UI, value: \"1\" } \
        - { name: HOMEBRIDGE_CONFIG_UI_HOST, value: \"0.0.0.0\" } \
        - { name: HOMEBRIDGE_CONFIG_UI_PORT, value: \"8581\" } \
        ports: \
        - { name: ui,  containerPort: 8581, protocol: TCP } \
        - { name: hap, containerPort: 51443, protocol: TCP } \
")'
	kubectl -n $(NS) rollout restart deploy/$(HB_DEP)
	kubectl -n $(NS) rollout status  deploy/$(HB_DEP) --timeout=180s

hb-svc-ing:
	kubectl -n $(NS) apply -f - <<'YAML'
apiVersion: v1
kind: Service
metadata: { name: homebridge, namespace: $(NS) }
spec:
  selector: { app: homebridge }
  ports:
  - { name: ui,    port: 8581, targetPort: 8581 }
  - { name: https, port: 51443, targetPort: 51443 }
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: { name: homebridge, namespace: $(NS) }
spec:
  rules:
  - host: $(HB_HOST)
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: { name: homebridge, port: { name: ui } }
YAML

hb-nodeport:
	kubectl -n $(NS) apply -f - <<'YAML'
apiVersion: v1
kind: Service
metadata: { name: homebridge-nodeport, namespace: $(NS) }
spec:
  selector: { app: homebridge }
  type: NodePort
  ports:
  - { name: ui, port: 8581, targetPort: 8581, nodePort: 30881 }
YAML
	@echo "Open: http://$$(kubectl -n $(NS) get pod -l app=homebridge -o jsonpath='{.items[0].status.hostIP}'):30881"

mdns-reflector-install:
	kubectl -n $(NS) apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata: { name: avahi-reflector, namespace: $(NS) }
data:
  avahi-daemon.conf: |
    [server]
    use-ipv4=yes
    use-ipv6=no
    allow-interfaces=eth0
    [wide-area]
    enable-wide-area=yes
    [publish]
    publish-hinfo=yes
    publish-workstation=yes
    [reflector]
    enable-reflector=yes
---
apiVersion: apps/v1
kind: DaemonSet
metadata: { name: avahi-reflector, namespace: $(NS) }
spec:
  selector: { matchLabels: { app: avahi-reflector } }
  template:
    metadata: { labels: { app: avahi-reflector } }
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: avahi
        image: ghcr.io/linuxserver/avahi:latest
        securityContext:
          capabilities: { add: ["NET_ADMIN","NET_RAW"] }
        volumeMounts:
        - { name: cfg, mountPath: /etc/avahi/avahi-daemon.conf, subPath: avahi-daemon.conf }
      volumes:
      - name: cfg
        configMap: { name: avahi-reflector }
YAML

mdns-reflector-uninstall:
	kubectl -n $(NS) delete ds avahi-reflector --ignore-not-found
	kubectl -n $(NS) delete cm avahi-reflector --ignore-not-found


