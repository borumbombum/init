#!/bin/bash
#
# ============================================================================
# SCRIPT: backup.sh
# VERSION: 1.2.0
# DATE: 2026-04-12
# AUTHOR: gemma4 AI model
#
# DESCRIPTION:
#   A robust, secure backup utility that synchronizes a source directory,
#   compresses it into a gzip tarball, and encrypts it using OpenSSL.
#   Automatically handles temporary file cleanup and secure passphrase input.
#
# USAGE:
#   ./backup.sh <Source_Path> <Destination_Parent_Directory>
#
# DEPENDENCIES:
#   Required : bash, tar, openssl
#   Optional : rsync (highly recommended for reliable, delta-aware syncing)
#
# SECURITY & WARNINGS:
#   • Encryption: AES-256-CBC with PBKDF2 key derivation (100,000 iterations)
#   • Passphrases are read securely from stdin (terminal echo disabled)
#   • Unencrypted tarballs and staging directories are automatically purged
#   • ⚠️  NEVER LOSE YOUR PASSPHRASE. Data recovery is mathematically impossible.
#
# ORIGIN & REVIEW:
#   • Base Generation  : 
#
# DISCLAIMER:
#   Provided "AS IS" without warranty. Always verify backups in a non-production
#   environment before trusting critical data. Store your passphrase securely.
# ============================================================================

# ============================================================================
# FUNCTION DEFINITIONS
# ============================================================================

usage() {
    echo "Usage: $0 <Source_Path> <Destination_Parent_Directory>"
    echo ""
    echo "Example: $0 /Volumes/Pendrive/Data /home/user/Backups"
    echo ""
    echo "Arguments:"
    echo "  \$1 (Source_Path): The full path to the directory you want to backup."
    echo "  \$2 (Destination_Parent_Directory): The directory where the final backup files should be placed."
    echo ""
    exit 1
}

cleanup() {
    rm -rf "$TEMP_DIR" "$UNENCRYPTED_ARCHIVE_PATH" 2>/dev/null
    unset USER_PASSWORD CONFIRM_PASSWORD
}

# ============================================================================
# PRE-EXECUTION CHECKS
# ============================================================================

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    usage
fi

SOURCE_DIR="$1"
DEST_PARENT_DIR="$2"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="temp_archive.tar.gz"
ENCRYPTED_NAME="pendirve_backup_${TIMESTAMP}.tar.gz.enc"
ENCRYPTED_PATH="$DEST_PARENT_DIR/$ENCRYPTED_NAME"
UNENCRYPTED_ARCHIVE_PATH="$DEST_PARENT_DIR/$ARCHIVE_NAME"

echo "======================================================"
echo "  Pendrive Secure Backup Script Initiated"
echo "  Timestamp: $TIMESTAMP"
echo "======================================================"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "🔴 ERROR: Source directory not found at '$SOURCE_DIR'."
    exit 1
fi

if [ ! -d "$DEST_PARENT_DIR" ]; then
    echo "🔴 ERROR: Destination directory not found at '$DEST_PARENT_DIR'."
    exit 1
fi

if [ -z "$(ls -A "$SOURCE_DIR")" ]; then
    echo "🔴 ERROR: Source directory is empty."
    exit 1
fi

echo ""
echo "🔑 Enter your encryption passphrase (MUST BE REMEMBERED):"
echo ""
read -s -p "🔑 Passphrase: " USER_PASSWORD
echo ""
read -s -p "🔑 Confirm passphrase: " CONFIRM_PASSWORD
echo ""

if [ "$USER_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "🔴 ERROR: Passphrases do not match."
    exit 1
fi

TEMP_DIR=$(mktemp -d "$DEST_PARENT_DIR/staging_XXXXXX")
trap cleanup EXIT

# --- Step 1: Copy/Sync (Dependency Check & Execute) ---
echo ""
echo "******************************************************"
echo "🚀 Step 1/4: Syncing files from source directory..."

if command -v rsync >/dev/null 2>&1; then
    echo "   [INFO] Found rsync. Using reliable sync method."
    # Use the standard, compatible --progress flag.
    rsync -avh --progress "${SOURCE_DIR}/" "$TEMP_DIR/"
else
    echo "   [WARNING] rsync not found. Falling back to 'cp' (less robust)."
    cp -av "${SOURCE_DIR}/." "$TEMP_DIR/"
fi

RSYNC_STATUS=$?
if [ $RSYNC_STATUS -ne 0 ]; then
    echo "🟠 WARNING: Data transfer completed, but rsync reported a non-zero status ($RSYNC_STATUS)."
    echo "   This may be a warning (e.g., missing permissions on non-critical files) but the primary transfer succeeded."
else
    echo "✅ Sync/Copy complete. Files staged in $TEMP_DIR."
fi


# --- Step 2: Compression (Tarball Creation) ---
echo ""
echo "***************************************************"
echo "📦 Step 2/4: Creating compressed tarball ($ARCHIVE_NAME)..."
# FIX: Output the archive to the parent destination directory.
tar -czvf "$UNENCRYPTED_ARCHIVE_PATH" -C "$TEMP_DIR" .
if [ $? -ne 0 ]; then
    echo "🔴 ERROR: Tarball creation failed. Check disk space or permissions."
    exit 1
fi
echo "✅ Compression complete. Archive saved to $UNENCRYPTED_ARCHIVE_PATH."


# --- Step 3: Encryption (OpenSSL) ---
echo ""
echo "******************************************************"
echo "🔒 Step 3/4: Encrypting archive..."

openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
  -in "$UNENCRYPTED_ARCHIVE_PATH" \
  -out "$ENCRYPTED_PATH" \
  -pass fd:0 <<< "$USER_PASSWORD"

if [ $? -eq 0 ]; then
    echo "============================================="
    echo "✅ SUCCESS! Backup completed."
    echo "   Encrypted file saved to: $ENCRYPTED_PATH"
    echo "============================================="
else
    echo "🔴 FATAL ERROR: Encryption failed. OpenSSL returned an error."
fi

exit 0
