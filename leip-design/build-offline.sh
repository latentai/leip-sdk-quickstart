#!/bin/bash
set -e

# Change to script's directory so relative paths work
cd "$(dirname "$0")"

# Remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^leip-build-temp$"; then
  echo "Found existing leip-build-temp container, removing it..."
  docker rm -f leip-build-temp
fi

echo "Starting container with GPU access from base image..."
docker run -d --gpus all --name leip-build-temp \
  -e LEIP_LICENSE_KEY=${LEIP_LICENSE_KEY} \
  repository.latentai.io/leip-design:${LEIP_DESIGN_VERSION} \
  sleep infinity

echo "Running Getting Started notebook to download models/recipes..."
docker exec leip-build-temp jupyter nbconvert \
  --to notebook \
  --execute \
  --inplace \
  /latentai/GettingStartedwithLEIPDesign.ipynb

echo "Creating directories in container..."
docker exec leip-build-temp mkdir -p /latentai/leip-design/notebooks
docker exec leip-build-temp mkdir -p /latentai/leip-optimize/notebooks

echo "Copying LEIP Design notebooks to container..."
docker cp ./notebooks/. leip-build-temp:/latentai/leip-design/notebooks/

echo "Copying LEIP Optimize notebooks to container..."
docker cp ../leip-optimize/notebooks/. leip-build-temp:/latentai/leip-optimize/notebooks/

echo "Copying LEIP Deploy notebooks to container..."
docker cp ../leip-deploy/notebooks/. leip-build-temp:/latentai/leip-deploy/notebooks/

echo "Copying LEIP Optimize setup script to container..."
docker cp leip_optimize_setup.sh leip-build-temp:/tmp/leip_optimize_setup.sh

echo "Running LEIP Optimize setup (installing packages and downloading models/datasets)..."
docker exec leip-build-temp bash /tmp/leip_optimize_setup.sh

echo "Cleaning up setup script..."
docker exec leip-build-temp rm /tmp/leip_optimize_setup.sh

echo "Copying vulnerability patch script to container..."
docker cp patch_vulnerabilities.sh leip-build-temp:/tmp/patch_vulnerabilities.sh

echo "Patching vulnerabilities..."
docker exec leip-build-temp bash /tmp/patch_vulnerabilities.sh

echo "Cleaning up patch script..."
docker exec leip-build-temp rm /tmp/patch_vulnerabilities.sh

echo "Committing container to final image without license key..."
docker commit \
  --change='ENV LEIP_LICENSE_KEY=' \
  --change='CMD ["jupyter", "lab", "--port=8888", "--ip=0.0.0.0", "--allow-root", "--no-browser"]' \
  leip-build-temp leip-design-offline:${LEIP_DESIGN_VERSION}
  # NOTE: Remove the line above (--change='ENV LEIP_LICENSE_KEY=') to bake the license key 
  # into the image at your own discretion. This is useful for internal-only images but
  # should be avoided if distributing the image externally.

echo "Removing temporary container..."
docker rm -f leip-build-temp

echo "Build complete!"