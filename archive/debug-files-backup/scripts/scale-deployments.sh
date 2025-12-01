#!/bin/bash
# Scaling automation script for Cat/Dog Voting App during load testing
# This script scales both Azure AKS and on-premises deployments

set -e

# Configuration
AZURE_NAMESPACE="default"
ONPREM_NAMESPACE="default"
AZURE_DEPLOYMENT="voting-app"
ONPREM_DEPLOYMENT="voting-app-onprem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Cat/Dog Voting App Scaling Automation${NC}"
echo -e "${BLUE}=======================================${NC}"

# Function to scale deployments
scale_deployment() {
    local context=$1
    local deployment=$2
    local namespace=$3
    local replicas=$4
    local environment=$5
    
    echo -e "${YELLOW}📈 Scaling $environment deployment to $replicas replicas...${NC}"
    
    if [ "$context" == "azure" ]; then
        # Scale Azure AKS deployment
        kubectl scale deployment $deployment --replicas=$replicas -n $namespace
    else
        # Scale on-premises deployment
        kubectl scale deployment $deployment --replicas=$replicas -n $namespace --context=$context
    fi
    
    echo -e "${GREEN}✅ $environment scaled to $replicas replicas${NC}"
}

# Function to monitor deployment status
monitor_deployment() {
    local context=$1
    local deployment=$2
    local namespace=$3
    local environment=$4
    
    echo -e "${YELLOW}👀 Monitoring $environment deployment status...${NC}"
    
    if [ "$context" == "azure" ]; then
        kubectl rollout status deployment/$deployment -n $namespace --timeout=300s
    else
        kubectl rollout status deployment/$deployment -n $namespace --context=$context --timeout=300s
    fi
}

# Function to get current replica count
get_replica_count() {
    local context=$1
    local deployment=$2
    local namespace=$3
    
    if [ "$context" == "azure" ]; then
        kubectl get deployment $deployment -n $namespace -o jsonpath='{.spec.replicas}'
    else
        kubectl get deployment $deployment -n $namespace --context=$context -o jsonpath='{.spec.replicas}'
    fi
}

# Main scaling workflow
echo -e "${BLUE}📊 Current Status:${NC}"
echo "Azure AKS replicas: $(get_replica_count azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE)"
echo "On-premises replicas: $(get_replica_count onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE)"
echo ""

# Phase 1: Scale down to 1 replica (simulate minimal resources)
echo -e "${RED}🔻 Phase 1: Scaling DOWN to 1 replica (testing minimal capacity)${NC}"
scale_deployment azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE 1 "Azure AKS"
scale_deployment onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE 1 "On-Premises"

echo -e "${YELLOW}⏳ Waiting for scale down to complete...${NC}"
monitor_deployment azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE "Azure AKS"
monitor_deployment onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE "On-Premises"

echo -e "${GREEN}✅ Phase 1 complete - both environments at 1 replica${NC}"
echo -e "${YELLOW}💤 Waiting 60 seconds to observe performance...${NC}"
sleep 60

# Phase 2: Scale up to 4 replicas (simulate load handling)
echo -e "${GREEN}🔺 Phase 2: Scaling UP to 4 replicas (testing scale-out capacity)${NC}"
scale_deployment azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE 4 "Azure AKS"
scale_deployment onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE 4 "On-Premises"

echo -e "${YELLOW}⏳ Waiting for scale up to complete...${NC}"
monitor_deployment azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE "Azure AKS"
monitor_deployment onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE "On-Premises"

echo -e "${GREEN}✅ Phase 2 complete - both environments at 4 replicas${NC}"

# Show current status
echo ""
echo -e "${BLUE}📈 Final Status:${NC}"
echo "Azure AKS replicas: $(get_replica_count azure $AZURE_DEPLOYMENT $AZURE_NAMESPACE)"
echo "On-premises replicas: $(get_replica_count onprem $ONPREM_DEPLOYMENT $ONPREM_NAMESPACE)"

# Show pods status
echo ""
echo -e "${BLUE}🏗️ Pod Status:${NC}"
echo -e "${YELLOW}Azure AKS Pods:${NC}"
kubectl get pods -n $AZURE_NAMESPACE -l app=$AZURE_DEPLOYMENT

echo -e "${YELLOW}On-Premises Pods:${NC}"
kubectl get pods -n $ONPREM_NAMESPACE -l app=$ONPREM_DEPLOYMENT --context=onprem

echo ""
echo -e "${GREEN}🎉 Scaling automation complete!${NC}"
echo -e "${BLUE}📊 Monitor the load test results to see how traffic distributed across scaled instances${NC}"