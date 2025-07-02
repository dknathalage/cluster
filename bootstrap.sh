#!/bin/bash

set -e

# Flux Bootstrap Script
# This script bootstraps Flux v2 on a Kubernetes cluster

# Configuration
export GITHUB_USER="${GITHUB_USER:-dknathalage}"
export GITHUB_TOKEN="${GITHUB_TOKEN}"
export GITHUB_REPO="${GITHUB_REPO:-cluster}"
export CLUSTER_NAME="${CLUSTER_NAME:-local}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed and cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not installed or cluster is not accessible"
        exit 1
    fi
    
    # Check if flux CLI is installed
    if ! command -v flux &> /dev/null; then
        log_error "Flux CLI is not installed. Please install it first:"
        echo "https://fluxcd.io/flux/installation/"
        exit 1
    fi
    
    # Check environment variables
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GITHUB_TOKEN is not set"
        exit 1
    fi
    
    if [[ "$GITHUB_USER" == "your-github-username" ]]; then
        log_error "Please set GITHUB_USER environment variable"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Bootstrap Flux
bootstrap_flux() {
    log_info "Bootstrapping Flux v2..."
    
    flux bootstrap github \
        --owner="$GITHUB_USER" \
        --repository="$GITHUB_REPO" \
        --branch=main \
        --path="./clusters/$CLUSTER_NAME" \
        --personal
    
    log_info "Flux bootstrap completed"
}

# Apply infrastructure and apps
apply_workloads() {
    log_info "Applying infrastructure and applications..."
    
    kubectl apply -f clusters/$CLUSTER_NAME/apps.yaml
    
    log_info "Workloads applied"
}

# Main execution
main() {
    log_info "Starting Flux bootstrap process..."
    
    check_prerequisites
    bootstrap_flux
    apply_workloads
    
    log_info "Bootstrap completed successfully!"
    log_info "You can check the status with: flux get kustomizations"
}

# Run main function
main "$@" 