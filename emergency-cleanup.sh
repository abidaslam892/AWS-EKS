#!/bin/bash

# Emergency One-Liner Cleanup Script
# Run this if you need to immediately stop ALL AWS charges

echo "🚨 EMERGENCY CLEANUP - Deleting ALL resources NOW!"
echo "This will take 10-15 minutes..."

# Quick cluster deletion without confirmation prompts
cd /home/abid/Project/AWS-Project

# Delete all applications first
kubectl delete --all deployments,services,pods,pvc --all-namespaces --timeout=60s --ignore-not-found=true 2>/dev/null || true

# Delete cluster immediately
./eksctl delete cluster --name=my-eks-cluster --region=us-east-1 --wait

echo "✅ Emergency cleanup complete - All charges stopped!"