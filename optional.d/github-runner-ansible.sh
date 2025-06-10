#!/bin/bash
set -e

### CONFIG ###
# These MUST be set before running - script will exit if still default values
GITHUB_REPO_URL="https://github.com/YOUR-ORG/YOUR-REPO"
RUNNER_NAME="pi-runner"
GITHUB_RUNNER_TOKEN="ghr_xxxxxxxxxxxxxxxxxxxxxxxxx"
RUNNER_USER="runner"
##############

echo "🔍 GitHub Actions Runner Setup Starting..."

# Check if running with sufficient privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: This script must be run as root or with sudo"
    echo "   Please run: sudo $0"
    exit 1
fi

# Validate configuration
if [ "$GITHUB_REPO_URL" = "https://github.com/YOUR-ORG/YOUR-REPO" ]; then
    echo "❌ ERROR: GITHUB_REPO_URL is not configured!"
    echo "   Please edit this script and set your actual repository URL."
    exit 1
fi

if [ "$GITHUB_RUNNER_TOKEN" = "ghr_xxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "❌ ERROR: GITHUB_RUNNER_TOKEN is not configured!"
    echo "   Please set a real GitHub runner registration token."
    echo "   Get one from: $GITHUB_REPO_URL/settings/actions/runners/new"
    exit 1
fi

echo "📥 Installing dependencies..."
apt update
apt install -y curl unzip jq python3-pip

echo "🐍 Installing Ansible..."
if ! pip3 install --break-system-packages ansible; then
    echo "❌ Failed to install Ansible"
    exit 1
fi

echo "👤 Creating runner user..."
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
    echo "✅ Created user: $RUNNER_USER"
else
    echo "ℹ️  User $RUNNER_USER already exists"
fi

echo "🔍 Gathering system labels..."
ARCH=$(uname -m)
case "$ARCH" in
  aarch64) PLATFORM="arm64"; LABEL_ARCH="64bit" ;;
  armv7l)  PLATFORM="arm";   LABEL_ARCH="32bit" ;;
  x86_64)  PLATFORM="x64";   LABEL_ARCH="64bit" ;;
  *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

MODEL="unknown"
if [ -f /proc/device-tree/model ]; then
    MODEL=$(tr -d '\0' < /proc/device-tree/model | sed 's/ /_/g')
fi
LABEL_MODEL=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
LABELS="pi,ansible,ts,$LABEL_ARCH,$LABEL_MODEL"

echo "📋 Runner will be registered with labels: $LABELS"

echo "🔧 Setting up GitHub runner as user $RUNNER_USER..."
# Create a script to run as the runner user
cat > /tmp/setup_runner.sh << 'RUNNER_SCRIPT'
#!/bin/bash
set -e
cd ~

echo "🔍 Getting latest runner version..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
if [ -z "$RUNNER_VERSION" ] || [ "$RUNNER_VERSION" = "null" ]; then
    echo "❌ Failed to get runner version from GitHub API"
    exit 1
fi

FILE=actions-runner-linux-PLATFORM-${RUNNER_VERSION#v}.tar.gz
echo "📥 Downloading: $FILE"

mkdir -p ~/actions-runner && cd ~/actions-runner
if ! curl -LO https://github.com/actions/runner/releases/download/$RUNNER_VERSION/$FILE; then
    echo "❌ Failed to download runner"
    exit 1
fi

echo "📦 Extracting runner..."
tar xzf $FILE && rm $FILE

echo "⚙️  Configuring runner..."
if ! ./config.sh --url "GITHUB_REPO_URL" \
                  --token "GITHUB_RUNNER_TOKEN" \
                  --name "RUNNER_NAME" \
                  --labels "LABELS" \
                  --unattended --replace; then
    echo "❌ Failed to configure runner"
    exit 1
fi

echo "✅ Runner configuration complete"
RUNNER_SCRIPT

# Replace placeholders in the script
sed -i "s/PLATFORM/$PLATFORM/g" /tmp/setup_runner.sh
sed -i "s|GITHUB_REPO_URL|$GITHUB_REPO_URL|g" /tmp/setup_runner.sh
sed -i "s/GITHUB_RUNNER_TOKEN/$GITHUB_RUNNER_TOKEN/g" /tmp/setup_runner.sh
sed -i "s/RUNNER_NAME/$RUNNER_NAME/g" /tmp/setup_runner.sh
sed -i "s/LABELS/$LABELS/g" /tmp/setup_runner.sh

# Make script executable and run as runner user
chmod +x /tmp/setup_runner.sh
if ! sudo -u "$RUNNER_USER" /tmp/setup_runner.sh; then
    echo "❌ Failed to set up runner as user $RUNNER_USER"
    rm -f /tmp/setup_runner.sh
    exit 1
fi

# Clean up temporary script
rm -f /tmp/setup_runner.sh

echo "🔧 Installing runner service..."
RUNNER_HOME="/home/$RUNNER_USER"
cd "$RUNNER_HOME/actions-runner"

if ! ./svc.sh install "$RUNNER_USER"; then
    echo "❌ Failed to install runner service"
    exit 1
fi

echo "🚀 Starting runner service..."
if ! ./svc.sh start; then
    echo "❌ Failed to start runner service"
    exit 1
fi

# Verify service is running
echo "⏳ Waiting for service to start..."
sleep 5

SERVICE_NAME=$(systemctl list-units --type=service --state=active | grep actions.runner | awk '{print $1}' | head -1)
if [ -n "$SERVICE_NAME" ] && systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ GitHub Actions runner installed and running!"
    echo "📊 Runner status:"
    systemctl status "$SERVICE_NAME" --no-pager -l
else
    echo "⚠️  Runner service may not be running properly"
    echo "📊 All runner services:"
    systemctl list-units actions.runner.* --no-pager || true
fi

echo "🎉 Setup complete! The runner should now be visible in your GitHub repository."
