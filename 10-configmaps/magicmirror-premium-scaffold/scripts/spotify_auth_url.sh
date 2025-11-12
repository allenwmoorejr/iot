#!/usr/bin/env bash
set -euo pipefail
CLIENT_ID="${1:-4e108b1ad6184b4fa3be7d07ce11ad09}"
REDIRECT_URI="${2:-https://mirror.suite.home.arpa/spotify/callback}"
SCOPE="user-read-playback-state user-read-currently-playing"
echo "Open this URL:"
printf "https://accounts.spotify.com/authorize?client_id=%s&response_type=code&redirect_uri=%s&scope=%s\n"   "$CLIENT_ID" "$REDIRECT_URI" "${SCOPE// /%20}"
