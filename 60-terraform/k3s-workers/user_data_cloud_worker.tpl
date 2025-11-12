#cloud-config
package_update: true
package_upgrade: false
packages:
  - curl
  - ca-certificates

write_files:
  - path: /etc/hostname
    permissions: "0644"
    content: |
      ${WORKER_NAME}

runcmd:
  # 1) Set hostname early
  - hostnamectl set-hostname ${WORKER_NAME}

  # 2) Install Tailscale
  - curl -fsSL https://tailscale.com/install.sh | sh

  # 3) Bring the node onto your tailnet
  - tailscale up --authkey=${TS_KEY} --hostname=${WORKER_NAME}

  # 4) Install K3s agent and join existing cluster via Tailscale URL
  - |
    curl -sfL https://get.k3s.io | \
      K3S_URL=${K3S_URL} \
      K3S_TOKEN='${K3S_TOKEN}' \
      sh -s - agent --node-name ${WORKER_NAME}

final_message: "cloud-init complete on ${WORKER_NAME}"

