#!/bin/bash

# Define variables
DOCKER_IMAGE_NAME="python-app"
DOCKER_TAG="latest"
KUBERNETES_FILE="manifests/python-app.yaml"
SERVICE_NAME="python-app-service"
METRICS_SERVER_URL="manifests/metrics-server.yaml"
METRICS_SERVER_API="v1beta1.metrics.k8s.io"

# Step 1: Install metrics-server
kubectl apply -f $METRICS_SERVER_URL

# Check if metrics-server is available
echo "Checking if metrics-server is available..."
RETRY_INTERVAL=5
RETRY_COUNT=0
MAX_RETRIES=20 # Adjust as needed

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    STATUS=$(kubectl get apiservice $METRICS_SERVER_API -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [ "$STATUS" = "True" ]; then
        echo "metrics-server is available."
        break
    else
        echo "Waiting for metrics-server to become available..."
        sleep $RETRY_INTERVAL
        ((RETRY_COUNT=RETRY_COUNT+1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "metrics-server did not become available in time. Exiting..."
    exit 1
fi
# Step 2: Build the Docker image
echo "Building Docker image..."
docker build -t $DOCKER_IMAGE_NAME:$DOCKER_TAG .

# Step 3: Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f $KUBERNETES_FILE

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/python-app

# Step 4: Set up port forwarding
echo "Setting up port forwarding..."
kubectl port-forward service/$SERVICE_NAME 8080:80 &

# Background process ID
PORT_FORWARD_PID=$!

# Wait a bit to ensure the port forwarding is established
sleep 5

MEMORY_CONSUME_ENDPOINT="http://localhost:8080/consume_memory"


# Step 5: Run tests to increase memory consumption
echo "Increasing memory consumption..."
for _ in {1..20}
do
    curl "$MEMORY_CONSUME_ENDPOINT"
    
    # Monitor and log memory usage
    echo "Memory usage after request:"
    kubectl top pod -l app=python-app --no-headers | awk '{print $1, $3}'
    
    sleep 1 # Wait for a second before the next call
done

# After increasing memory consumption, fetch and output logs
echo "Fetching logs from the container..."
POD_NAME=$(kubectl get pod -l app=python-app -o jsonpath="{.items[0].metadata.name}")
kubectl logs "$POD_NAME"

# After the script is done, kill the port forwarding process
kill $PORT_FORWARD_PID
