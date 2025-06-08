#!/bin/bash
set -e

### CONFIG ###
GITHUB_REPO_URL="https://github.com/YOUR-ORG/YOUR-REPO"
RUNNER_NAME="pi-tailscale"
GITHUB_RUNNER_TOKEN="ghr_xxxxxxxxxxxxxxxxxxxxxxxxx"
TAILSCALE_AUTHKEY="tskey-xxxxxxxxxxxxxxxxxxxxxxxx"
RUNNER_USER="runner"
##############

echo "⏳ Waiting for network..."
for i in {1..30}; do
  if hostname -I | grep -q '\.'; then
    echo "✅ Network is up!"
    break
  fi
  sleep 2
done

if ! hostname -I | grep -q '\.'; then
  echo "❌ No network after 60s. Aborting runner setup."
  exit 1
fi

echo "📥 Installing Tailscale and Ansible..."
apt install -y curl unzip jq python3-pip
pip3 install --break-system-packages ansible
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey "$TAILSCALE_AUTHKEY" --ssh --hostname "$RUNNER_NAME"

echo "👤 Creating runner user..."
useradd -m -s /bin/bash "$RUNNER_USER" || true

echo "🔍 Gathering system labels..."
ARCH=$(uname -m)
case "$ARCH" in
  aarch64) PLATFORM="arm64"; LABEL_ARCH="64bit" ;;
  armv7l)  PLATFORM="arm";   LABEL_ARCH="32bit" ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac
MODEL=$(tr -d '\0' < /proc/device-tree/model | sed 's/ /_/g')
LABEL_MODEL=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
LABELS="pi,ansible,ts,$LABEL_ARCH,$LABEL_MODEL"

echo "🔧 Installing GitHub runner..."
sudo -u "$RUNNER_USER" bash <<EOF
cd ~
RUNNER_VERSION=\$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
FILE=actions-runner-linux-${PLATFORM}-\${RUNNER_VERSION#v}.tar.gz

mkdir -p ~/actions-runner && cd ~/actions-runner
curl -LO https://github.com/actions/runner/releases/download/\$RUNNER_VERSION/\$FILE
tar xzf \$FILE && rm \$FILE

./config.sh --url "$GITHUB_REPO_URL" \
            --token "$GITHUB_RUNNER_TOKEN" \
            --name "$RUNNER_NAME" \
            --labels "$LABELS" \
            --unattended --replace

sudo ./svc.sh install
sudo ./svc.sh start
EOF

echo "✅ GitHub Actions runner installed and active."
