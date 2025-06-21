#!/bin/bash

# --- YOUR CONFIGURATION ---
# YOUR MONERO WALLET ADDRESS
WALLET_ADDRESS="85JiygdevZmb1AxUosPHyxC13iVu9zCydQ2mDFEBJaHp2wyupPnq57n6bRcNBwYSh9bA5SA4MhTDh9moj55FwinXGn9jDkz"

# MONERO MINING POOL (HashVault.pro is a good example)
MINING_POOL="pool.hashvault.pro:443"

# PASSWORD OR WORKER NAME (usually 'x' or any name)
POOL_PASSWORD="x"

# --- Script Start ---

echo "Starting XMRig setup and Monero mining (normal mode)..."

# 1. Update system and install necessary packages
echo "Updating system and installing necessary packages (wget, build-essential/cmake, libuv, libssl, libhwloc)..."
# Check for Debian/Ubuntu
if command -v apt &> /dev/null; then
    sudo apt update -y
    sudo apt install -y wget build-essential cmake libuv1-dev libssl-dev libhwloc-dev
# Check for CentOS/RHEL
elif command -v yum &> /dev/null; then
    sudo yum install -y epel-release
    sudo yum install -y wget gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel
else
    echo "Unsupported OS or package manager (apt/yum) not found."
    echo "Please install wget, build-essential/gcc-c++/make, cmake, libuv-dev, libssl-dev, libhwloc-dev manually."
    exit 1
fi

# 2. Download XMRig
echo "Downloading the latest XMRig for Linux..."
# Latest XMRig URL for Linux x64 static - ALWAYS CHECK FOR THE LATEST VERSION ON XMRIG'S GITHUB RELEASES
XMRIG_VERSION="6.23.0" # Make sure this is the current latest or desired version
XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-linux-static-x64.tar.gz"

XMRIG_ARCHIVE=$(basename "$XMRIG_URL")
XMRIG_DIR="xmrig-${XMRIG_VERSION}"

echo "Downloading XMRig from: $XMRIG_URL"
wget "$XMRIG_URL" -P /tmp --show-progress # Download to /tmp to keep current directory clean

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error: Could not download XMRig from $XMRIG_URL. Please check the URL or your internet connection."
    exit 1
fi

# 3. Extract XMRig
echo "Extracting XMRig..."
mkdir -p "$XMRIG_DIR" # Create directory if it doesn't exist
tar -xzf "/tmp/$XMRIG_ARCHIVE" -C "$XMRIG_DIR" --strip-components=1 # Extract into a clean directory
if [ ! -f "$XMRIG_DIR/xmrig" ]; then # Check for the xmrig executable specifically
    echo "Error: Extraction failed. XMRig executable not found after extraction."
    echo "Please check the archive file ($XMRIG_ARCHIVE) and the target directory ($XMRIG_DIR)."
    exit 1
fi

# 4. Navigate into XMRig directory and grant execute permissions
echo "Navigating into XMRig directory and granting execute permissions..."
cd "$XMRIG_DIR" || { echo "Error: Could not change directory to $XMRIG_DIR."; exit 1; }
chmod +x xmrig

# 5. Create JSON configuration file (XMRig will use all CPU threads by default)
echo "Creating config.json file for XMRig..."
cat <<EOF > config.json
{
    "autosave": true,
    "cpu": true,      // Enable CPU mining, uses all threads by default
    "opencl": false,  // Disable OpenCL (AMD GPU mining)
    "cuda": false,    // Disable CUDA (Nvidia GPU mining)
    "pools": [
        {
            "algo": "rx/0",    // Explicitly set algorithm for better compatibility (RandomX)
            "coin": "monero",  // Explicitly set coin
            "url": "$MINING_POOL",
            "user": "$WALLET_ADDRESS",
            "pass": "$POOL_PASSWORD",
            "keepalive": true,
            "tls": true        // Enable TLS for secure connection if pool supports it (HashVault does)
        }
    ]
}
EOF

# 6. Run XMRig directly
echo "Starting Monero mining with XMRig..."
echo "Using wallet address: $WALLET_ADDRESS"
echo "Connecting to pool: $MINING_POOL"
echo "To stop mining, press Ctrl+C."

# Run xmrig using the configuration file directly in the terminal
./xmrig -c config.json

echo "XMRig has stopped."
