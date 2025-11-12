#!/usr/bin/env bash
set -euo pipefail
CLIENT_ID="${1:?client id}"
CLIENT_SECRET="${2:?client secret}"
CODE="${3:?auth code}"
REDIRECT_URI="${4:-https://mirror.suite.home.arpa/spotify/callback}"
curl -s -X POST "https://accounts.spotify.com/api/token"   -H "Content-Type: application/x-www-form-urlencoded"   -u "${CLIENT_ID}:${CLIENT_SECRET}"   -d "grant_type=authorization_code&code=${CODE}&redirect_uri=${REDIRECT_URI}"
echo
