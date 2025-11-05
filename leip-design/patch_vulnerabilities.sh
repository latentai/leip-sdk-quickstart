#!/bin/bash
set -e

echo "Updating system packages..."
apt-get update && \
apt-get install -y --only-upgrade \
  perl \
  perl-base \
  perl-modules-5.36 \
  python3-pkg-resources \
  linux-libc-dev \
  linux-libc-dev-arm64-cross && \
apt-get upgrade -y && \
apt-get clean && \
rm -rf /var/lib/apt/lists/*

echo "Updating Python packages with known vulnerabilities..."
pip install --no-cache-dir --upgrade \
  GitPython>=3.1.41 \
  starlette>=0.49.1 \
  Brotli>=1.2.0

echo "Vulnerability patching complete!"