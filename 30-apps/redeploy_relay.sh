kubectl -n suite apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: micro-cam-relay
  namespace: suite
  labels: { app: micro-cam-relay }
spec:
  replicas: 1
  selector:
    matchLabels: { app: micro-cam-relay }
  template:
    metadata:
      labels: { app: micro-cam-relay }
    spec:
      nodeSelector:
        kubernetes.io/hostname: m3
      volumes:
        - name: shared
          emptyDir: {}
        - name: acm0
          hostPath:
            path: /dev/ttyACM0
            type: CharDevice
      initContainers:
        - name: init-fifo
          image: alpine:3.20
          command: ["sh","-lc"]
          args:
            - set -eu; mkfifo -m 666 /shared/in.mjpeg; : > /shared/tap.bin; ls -l /shared
          volumeMounts:
            - { name: shared, mountPath: /shared }
      containers:
        # Reads bytes from the UNO and writes to FIFO + tap.bin (for inspection)
        - name: serial-cat
          image: alpine:3.20
          securityContext: { privileged: true }
          env:
            - { name: DEV,  value: "/dev/ttyACM0" }
            - { name: BAUD, value: "115200" }
          volumeMounts:
            - { name: shared, mountPath: /shared }
            - { name: acm0,   mountPath: /dev/ttyACM0 }
          command: ["sh","-lc"]
          args: |
            set -eux
            ls -l "$DEV" || true
            stty -F "$DEV" "$BAUD" cs8 -cstopb -parenb -ixon -ixoff -echo raw -hupcl || true
            echo "[serial-cat] first 64 bytes:"
            timeout 2 dd if="$DEV" bs=1 count=64 2>/dev/null | hexdump -C || true
            echo "[serial-cat] tee $DEV -> /shared/in.mjpeg and /shared/tap.bin"
            # cat -> tee: write to both fifo and capture file
            exec cat "$DEV" | tee -a /shared/tap.bin > /shared/in.mjpeg

        # Repackages MJPEG to H.264 and publishes to MediaMTX at /porch
        - name: ffmpeg
          image: ghcr.io/linuxserver/ffmpeg:latest
          env: [ { name: FPS, value: "5" } ]
          volumeMounts: [ { name: shared, mountPath: /shared } ]
          command: ["/bin/sh","-lc"]
          args: |
            set -eux
            while [ ! -p /shared/in.mjpeg ]; do ls -l /shared; sleep 1; done
            ffmpeg -hide_banner -loglevel info -re \
                   -fflags nobuffer -flags low_delay -use_wallclock_as_timestamps 1 \
                   -f mjpeg -framerate "$FPS" -i /shared/in.mjpeg \
                   -c:v libx264 -preset veryfast -tune zerolatency \
                   -pix_fmt yuv420p -profile:v baseline -level 3.1 \
                   -x264-params keyint=30:min-keyint=30:scenecut=0 \
                   -g 30 -b:v 1200k -maxrate 1500k -bufsize 2400k \
                   -an -f rtsp -rtsp_transport tcp -muxdelay 0.1 \
                   rtsp://mediamtx.suite.svc.cluster.local:8554/porch
YAML

kubectl -n suite rollout status deploy/micro-cam-relay

