# LEIP Docker Setup

Docker Compose setup for LEIP Design and LEIP Optimize with GPU support.

## Prerequisites

- Docker and Docker Compose
- NVIDIA GPU with drivers
- NVIDIA Container Toolkit
- LatentAI credentials (Repository Token & License Key)

### Cloud Setup (AWS)

- g4dn.xlarge EC2 instance
- Deep Learning OSS Nvidia Driver AMI GPU TensorFlow 2.18 (Ubuntu 22.04)
- 150GB of storage

## Quick Start

### 1. Initial Setup

Configure credentials and generate .env file:

```bash
source setup.sh
```

You'll be prompted for:
- Repository Token Name
- Repository Token Passcode
- LEIP License Key

### 2. Start Services

Choose **one** of the following:
```bash
# LEIP Design with Jupyter (includes optimize functionality)
# Includes tutorial notebooks for both Design and Optimize
docker compose --profile leip-design up

# LEIP Optimize standalone with Jupyter
# Includes tutorial notebooks for Optimize only
docker compose --profile leip-optimize-jupyter up

# LEIP Optimize bash shell (detached, for CLI workflows)
# Does not include tutorial notebooks
docker compose --profile leip-optimize-bash up -d
docker compose exec leip-optimize-bash bash
```

**Note:** Notebook availability can be adjusted in `docker-compose.yml` volume mounts.

### 2b. Offline Mode (Alternative to Step 2)
```bash
# Build offline image (first time only)
./leip-design/build-offline.sh

# Run offline mode
docker compose --profile leip-design-offline up
```

#### Creating a Tarball for Transfer
```bash
# Save the image as a compressed tarball
docker save leip-design-offline:${LEIP_DESIGN_VERSION} | gzip > leip-design-offline-${LEIP_DESIGN_VERSION}.tar.gz

# Transfer to target machine, then load:
docker load -i leip-design-offline-${LEIP_DESIGN_VERSION}.tar.gz

# Run the loaded image
docker compose --profile leip-design-offline up
```

### 3. Stop Services
```bash
# Stop containers (preserves container state)
docker compose stop

# Stop and remove containers (clean shutdown)
docker compose down
```

**Note:** `stop` pauses containers for quick restart. `down` removes containers but preserves volumes.

## Configuration

Default ports:
- LEIP Design: 8888
- LEIP Optimize: 8889
- TensorBoard: 6006

To change versions or ports, edit `.env` or re-run `source setup.sh`.

## Directory Structure

```
.
├── setup.sh                 # Interactive setup script
├── docker-compose.yml       # Service definitions
├── .env                     # Generated configuration (do not commit)
├── workspace/               # LEIP Design workspace
├── latentai/                # LEIP Optimize workspace
└── leip-design/
    └── build-offline.sh     # Offline image builder
```