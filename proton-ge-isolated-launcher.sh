#!/bin/bash

# 1 Print launch visual output
echo "========================================="
echo "    Proton-GE Bottles Auto-Launcher      "
echo "========================================="

# Extract paths and cleanly format the bottle name
EXE_PATH=$(realpath "$1")
EXE_NAME=$(basename -- "$EXE_PATH" | sed 's/\.[^.]*$//')
BOTTLE_NAME=$(echo "$EXE_NAME" | tr -s ' ' '_' | tr -cd '[:alnum:]_')

echo "[*] Target Executable: $EXE_PATH"
echo "[*] Assigned Prefix: $BOTTLE_NAME"

# 2 Locates the Proton-GE runner
RUNNER_FOLDER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners"
RUNNER_NAME=$(ls -1 "$RUNNER_FOLDER" 2>/dev/null | grep -i 'GE-Proton' | sort -V | tail -n 1)

if [ -z "$RUNNER_NAME" ]; then
    echo "[!] ERROR: GE-Proton not found inside Bottles."
    echo "    Make sure ProtonUp-Qt installed it to the Bottles Flatpak."
    read -p "Press Enter to exit..."
    exit 1
fi
echo "[*] Using Runner: $RUNNER_NAME"

# 3 Create the isolated Bottle if it doesn't exist
# Point to the default Flatpak Bottles directory
PREFIX_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles"
PREFIX_DIR="$PREFIX_BASE/$BOTTLE_NAME"

if [ ! -d "$PREFIX_DIR" ]; then
    echo "[*] Prefix not found. Initializing new isolated Bottle ($BOTTLE_NAME)..."

    # Using strict long-flags to ensure CLI version compatibility across different systems
    flatpak run --command=bottles-cli com.usebottles.bottles new \
        --bottle-name "$BOTTLE_NAME" \
        --environment application \
        --runner "$RUNNER_NAME"

    # Validation check to ensure Bottles didn't silently crash
    if [ ! -d "$PREFIX_DIR" ]; then
        echo ""
        echo "[!] CRITICAL ERROR: Bottles failed to generate the prefix folder at:"
        echo "    $PREFIX_DIR"
        echo "    Fix 1: Ensure you created a 'Test' bottle manually in the GUI."
        echo "    Fix 2: Ensure Bottles has WRITE access."
        read -p "Press Enter to exit..."
        exit 1
    fi
    echo "[*] Prefix successfully generated."
fi

# 4 Launch the application inside the sandbox
echo "[*] Launching application securely..."
flatpak run --command=bottles-cli com.usebottles.bottles run \
    --bottle "$BOTTLE_NAME" \
    --executable "$EXE_PATH"

# Keep the terminal window open briefly to read potential errors
sleep 3
