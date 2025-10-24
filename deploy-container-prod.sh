#!/bin/bash
# ==============================================================================
# Configuration
# ==============================================================================
# The name and tag of the Docker image to test (e.g., nginx:latest)
IMAGE_NAME="devopsproject1"
# The name to assign to the temporary container
CONTAINER_NAME="prod-app-$(date +%s)"
# The port the application inside the container is expected to listen on
CONTAINER_PORT="80"
# ==============================================================================
# Main script execution
# ==============================================================================
echo "Starting prod container '${CONTAINER_NAME}' from image '${IMAGE_NAME}' in detached mode..."
if ! sudo docker run -itd -p 91:80 --name "${CONTAINER_NAME}" "${IMAGE_NAME}"; then
  echo "ERROR: Failed to start the Docker container from image '${IMAGE_NAME}'."
  # The container was never created, so we don't need `cleanup_container`
  # but if we determine the image is the problem, it's appropriate to remove it.
  # For now, we assume the run failure may not be image-related.
  exit 1
else
  exit 0 # Indicate success for the pipeline step
fi
