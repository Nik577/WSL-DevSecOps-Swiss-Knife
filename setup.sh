#!/bin/bash
#===============================================================================
# WSL-DevSecOps-Swiss-Knife Setup Script v2.9
# Optimized for: Ubuntu 24.04 (WSL2)
# Author: Nik577 (Nikita Mamonov)
# GitHub: https://github.com/Nik577/WSL-DevSecOps-Swiss-Knife
#===============================================================================

set -e

# --- 0. Robustness Check ---
if ! pwd >/dev/null 2>&1; then cd "$HOME"; fi
USER_NAME=$(whoami)

# --- Colors & UI ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_PURPLE='\033[0;35m'
C_NC='\033[0m'
BOLD='\033[1m'

function render_header() {
    clear
    echo -e "${C_CYAN}"
    echo "  WSL-DevSecOps-Swiss-Knife"
    echo "  -----------------------------------------------------------"
    echo -e "  Version: 2.9 | User: ${USER_NAME}"
    echo -e "  -----------------------------------------------------------${C_NC}\n"
}

render_header

# --- 1. Docker Engine Upgrade & API Fix ---
echo -e "${C_PURPLE}[PHASE 0] Deploying Docker Engine${C_NC}"
sudo apt update -qq
sudo apt install -y ca-certificates curl gnupg > /dev/null
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -qq
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null

if ! docker info >/dev/null 2>&1; then
    sudo service docker restart
    sleep 3
    sudo chmod 666 /var/run/docker.sock || true
fi
export DOCKER_API_VERSION=1.44

# --- 2. System Utilities ---
echo -e "\n${C_PURPLE}[PHASE 1] Installing Base Utilities${C_NC}"
sudo apt install -y -qq git wget jq tree unzip zip build-essential lsb-release python3-pip python3-venv pipx htop neovim > /dev/null
pipx ensurepath --force > /dev/null
export PATH="$PATH:$HOME/.local/bin"

# --- 3. asdf Version Manager ---
echo -e "\n${C_PURPLE}[PHASE 2] Configuring asdf Runtime Manager${C_NC}"
if [ ! -d "$HOME/.asdf" ]; then
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0 -q
fi
. "$HOME/.asdf/asdf.sh"

function tool_installer() {
    local p=$1; local v=${2:-latest}; local u=$3
    cd "$HOME"
    if ! asdf plugin list | grep -q "^$p$"; then [ -n "$u" ] && asdf plugin add "$p" "$u" || asdf plugin add "$p"; fi
    if ! asdf list "$p" 2>/dev/null | grep -q "$v"; then asdf install "$p" "$v"; fi
    asdf global "$p" "$v"
    echo -e "  - ${p} v${v} [INSTALLED]"
}

tool_installer opentofu 1.6.2
tool_installer kubectl 1.29.2
tool_installer helm 3.14.2
tool_installer k9s
tool_installer trivy
tool_installer gitleaks
tool_installer hadolint
tool_installer lazygit

# --- 4. k3d Cluster Deployment ---
echo -e "\n${C_PURPLE}[PHASE 3] Initializing Kubernetes Environment${C_NC}"
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash > /dev/null
fi

if ! k3d cluster list | grep -q "devsecops-lab"; then
    DOCKER_API_VERSION=1.44 k3d cluster create devsecops-lab -p "8081:80@loadbalancer" --agents 1 --k3s-arg "--disable=traefik@server:0"
fi

kubectl config use-context k3d-devsecops-lab

# Deploying Target Application (OWASP Juice Shop)
kubectl create ns simulation --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl create deployment juice-shop --image=bkimminich/juice-shop -n simulation --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl expose deployment juice-shop --port=3000 --target-port=3000 -n simulation --dry-run=client -o yaml | kubectl apply -f - > /dev/null

# --- 5. Final Summary ---
echo -e "\n${C_CYAN}-----------------------------------------------------------"
echo -e " SETUP COMPLETE"
echo -e "-----------------------------------------------------------${C_NC}"
echo -e "\nDevOps is asking the question - What if we bring best practices in"
echo -e "software engineering to infrastructure?... and never answering.\n"
echo -e "Deployment Objectives:"
echo -e " 1. Security Audit: trivy k8s --namespace simulation all"
echo -e " 2. Cluster Observability: k9s"
echo -e " 3. Secret Scanning: gitleaks detect -v"
echo -e "\nEnvironment ready for: ${USER_NAME}"
echo -e "${C_CYAN}-----------------------------------------------------------${C_NC}"
