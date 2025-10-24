#!/bin/bash
# ==============================================================================
# Configuration
# ==============================================================================
# The name and tag of the Docker image to test (e.g., nginx:latest)
IMAGE_NAME="devopsproject1"
# The name to assign to the temporary container
CONTAINER_NAME="internal-test-$(date +%s)"
# The port the application inside the container is expected to listen on
CONTAINER_PORT="80"
# The URL to check inside the container. Always use 'localhost'.
HEALTH_CHECK_URL="http://localhost:${CONTAINER_PORT}"
# How long to wait in total before giving up (in seconds)
TIMEOUT_SECONDS=10
# How long to wait between retries (in seconds)
RETRY_INTERVAL=5
# ==============================================================================
# Functions
# ==============================================================================
# Function to clean up the temporary container
cleanup_container() {
  echo "Cleaning up container ${CONTAINER_NAME}..."
  # The `|| true` prevents the script from failing if the container isn't there
  sudo docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  sudo docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
# Function to clean up the container AND the image
cleanup_all() {
  cleanup_container
  echo "Cleaning up image ${IMAGE_NAME}..."
  sudo docker rmi "${IMAGE_NAME}" >/dev/null 2>&1 || true
}
# ==============================================================================
# Main script execution
# ==============================================================================
# Ensure the temporary container is always cleaned up on exit
trap cleanup_container EXIT
# Stage 1: Run the container in detached mode
echo "Starting test container '${CONTAINER_NAME}' from image '${IMAGE_NAME}' in detached mode..."
if ! sudo docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}"; then
  echo "ERROR: Failed to start the Docker container from image '${IMAGE_NAME}'."
  # The container was never created, so we don't need `cleanup_container`
  # but if we determine the image is the problem, it's appropriate to remove it.
  # For now, we assume the run failure may not be image-related.
  exit 1
fi
# Stage 2: Wait for the service to become ready using an internal health check
echo "Waiting for internal service to respond at ${HEALTH_CHECK_URL}..."
for i in $(seq 1 $((TIMEOUT_SECONDS / RETRY_INTERVAL))); do
  if sudo docker exec "${CONTAINER_NAME}" curl --output /dev/null --silent --head --fail "${HEALTH_CHECK_URL}"; then
    echo "Health check successful! The service is exposed on port ${CONTAINER_PORT} internally."
    exit 0 # Indicate success for the pipeline step
  else
    echo "Health check failed (attempt $i). Retrying in ${RETRY_INTERVAL} seconds..."
    sleep "${RETRY_INTERVAL}"
  fi
done
# If the loop finishes without a successful health check, it's a failure
echo "ERROR: Health check failed after ${TIMEOUT_SECONDS} seconds. Exiting with failure."
# The container was running, but the test failed, indicating a bad image.
cleanup_all
exit 1
