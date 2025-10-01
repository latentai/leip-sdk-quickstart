#!/bin/bash

# LEIP Environment Setup Script
# This script interactively configures .env file and exports variables

# set -e  # Commented out - causes shell to exit when sourced

echo "🚀 LEIP Environment Setup"
echo "========================"

# Load existing .env if it exists
if [[ -f .env ]]; then
    echo "📋 Loading existing .env file..."
    set -a
    source .env 2>/dev/null || true  # Don't fail if .env has issues
    set +a
fi

# Set current defaults from your .env file
DEFAULT_LEIP_DESIGN_VERSION="${LEIP_DESIGN_VERSION:-v1.5.4}"
DEFAULT_LEIP_OPTIMIZE_VERSION="${LEIP_OPTIMIZE_VERSION:-5.1.1}"
DEFAULT_DESIGN_PORT="${DESIGN_PORT:-8888}"
DEFAULT_OPTIMIZE_PORT="${OPTIMIZE_PORT:-8889}"
DEFAULT_REPOSITORY_TOKEN_NAME="${REPOSITORY_TOKEN_NAME:-}"
DEFAULT_REPOSITORY_TOKEN_PASSCODE="${REPOSITORY_TOKEN_PASSCODE:-}"
DEFAULT_LEIP_LICENSE_KEY="${LEIP_LICENSE_KEY:-}"

# Auto-set version and port values (no prompting needed)
LEIP_DESIGN_VERSION="$DEFAULT_LEIP_DESIGN_VERSION"
LEIP_OPTIMIZE_VERSION="$DEFAULT_LEIP_OPTIMIZE_VERSION"
DESIGN_PORT="$DEFAULT_DESIGN_PORT"
OPTIMIZE_PORT="$DEFAULT_OPTIMIZE_PORT"

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local hide_input="${4:-false}"
    
    if [[ "$hide_input" == "true" ]]; then
        if [[ -n "$default" ]]; then
            echo -n "$prompt [$default]: "
            read -s input
            echo ""  # New line after hidden input
        else
            echo -n "$prompt: "
            read -s input
            echo ""
        fi
    else
        echo -n "$prompt [$default]: "
        read input
    fi
    
    # Use default if input is empty
    if [[ -z "$input" ]]; then
        input="$default"
    fi
    
    # Set the variable
    eval "$var_name='$input'"
}

echo ""
echo "Configure your LEIP environment (press Enter to use defaults):"
echo ""

# Only prompt for credentials and license key
echo "Repository Credentials:"
prompt_with_default "Repository Token Name" "$DEFAULT_REPOSITORY_TOKEN_NAME" "REPOSITORY_TOKEN_NAME"
prompt_with_default "Repository Token Passcode" "$DEFAULT_REPOSITORY_TOKEN_PASSCODE" "REPOSITORY_TOKEN_PASSCODE" true

echo ""
echo "License Key (Required):"
prompt_with_default "LEIP License Key" "$DEFAULT_LEIP_LICENSE_KEY" "LEIP_LICENSE_KEY" true

# Write to .env file
echo ""
echo "💾 Writing configuration to .env file..."

cat > .env << EOF
# Image versions
LEIP_DESIGN_VERSION=$LEIP_DESIGN_VERSION
LEIP_OPTIMIZE_VERSION=$LEIP_OPTIMIZE_VERSION

# Jupyter notebook ports
DESIGN_PORT=$DESIGN_PORT
OPTIMIZE_PORT=$OPTIMIZE_PORT

# Repository credentials
REPOSITORY_TOKEN_NAME=$REPOSITORY_TOKEN_NAME
REPOSITORY_TOKEN_PASSCODE=$REPOSITORY_TOKEN_PASSCODE
EOF

# Add license key to .env file
echo "" >> .env
echo "# License key" >> .env
echo "LEIP_LICENSE_KEY=$LEIP_LICENSE_KEY" >> .env

# Export all variables for current session
echo "📤 Exporting environment variables..."
set -a
source .env
set +a

# Verify required variables are set
required_vars=("REPOSITORY_TOKEN_NAME" "REPOSITORY_TOKEN_PASSCODE" "LEIP_DESIGN_VERSION" "LEIP_OPTIMIZE_VERSION" "LEIP_LICENSE_KEY")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "❌ Error: Missing required variables:"
    printf '   - %s\n' "${missing_vars[@]}"
    return 1
fi

# Display configuration (hide sensitive values)
echo ""
echo "✅ Configuration complete:"
echo "   LEIP_DESIGN_VERSION: $LEIP_DESIGN_VERSION"
echo "   LEIP_OPTIMIZE_VERSION: $LEIP_OPTIMIZE_VERSION"
echo "   DESIGN_PORT: $DESIGN_PORT"
echo "   OPTIMIZE_PORT: $OPTIMIZE_PORT"
echo "   REPOSITORY_TOKEN_NAME: $REPOSITORY_TOKEN_NAME"
echo "   REPOSITORY_TOKEN_PASSCODE: [HIDDEN]"
echo "   LEIP_LICENSE_KEY: [SET]"

# Docker login
echo ""
echo "🔐 Logging into Docker registry..."
if echo "$REPOSITORY_TOKEN_PASSCODE" | docker login repository.latentai.io -u "$REPOSITORY_TOKEN_NAME" --password-stdin; then
    echo "✅ Successfully logged into repository.latentai.io"
else
    echo "❌ Failed to login to Docker registry"
    echo "Please check your credentials and try again"
    return 1
fi

echo ""
echo "🎉 Setup complete! You can now run:"
echo "   docker compose --profile leip-design up                (online mode)"
echo ""
echo "   For offline mode:"
echo "   ./leip-design/build-offline.sh                         (build offline image)"
echo "   docker compose --profile leip-design-offline up        (run offline mode)"
echo ""
echo "   Other services:"
echo "   docker compose --profile leip-optimize-jupyter up"
echo "   docker compose --profile leip-optimize-bash up -d"
echo ""
echo "💡 Tip: Combine profiles to run multiple services:"
echo "   docker compose --profile leip-design --profile leip-optimize-jupyter up"
echo ""
echo "💡 Tip: Run 'source setup.sh' again anytime to reconfigure"