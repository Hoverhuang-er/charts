#!/bin/bash

# Script to register Helm repository with ArtifactHub
# Usage: ./register-artifacthub.sh

set -euo pipefail

echo "📦 Registering Helm repository with ArtifactHub..."
echo ""

# Check if API credentials are set
if [[ -z "${ARTIFACTHUB_API_KEY:-}" ]] || [[ -z "${ARTIFACTHUB_API_SEC:-}" ]]; then
    echo "❌ Error: ARTIFACTHUB_API_KEY and ARTIFACTHUB_API_SEC environment variables must be set"
    echo ""
    echo "Export them from your secrets:"
    echo "  export ARTIFACTHUB_API_KEY='your-key-id'"
    echo "  export ARTIFACTHUB_API_SEC='your-key-secret'"
    exit 1
fi

# Repository configuration
REPO_NAME="hoverhuang-er-charts"
DISPLAY_NAME="Helm Charts Collection"
REPO_URL="https://hoverhuang-er.github.io/charts/"
REPO_KIND=0  # 0 = Helm charts

echo "Repository Details:"
echo "  Name: ${REPO_NAME}"
echo "  Display Name: ${DISPLAY_NAME}"
echo "  URL: ${REPO_URL}"
echo "  Kind: Helm"
echo ""

# Make API call
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST https://artifacthub.io/api/v1/repositories \
  -H "Content-Type: application/json" \
  -H "X-API-Key-ID: ${ARTIFACTHUB_API_KEY}" \
  -H "X-API-Key-Secret: ${ARTIFACTHUB_API_SEC}" \
  -d "{
    \"name\": \"${REPO_NAME}\",
    \"display_name\": \"${DISPLAY_NAME}\",
    \"url\": \"${REPO_URL}\",
    \"kind\": ${REPO_KIND},
    \"repository_id\": \"${REPO_NAME}\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "API Response:"
echo "  HTTP Status: ${HTTP_CODE}"

if [[ -n "${BODY}" ]]; then
    echo "  Response Body: ${BODY}"
fi
echo ""

if [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Repository successfully registered!"
    echo ""
    echo "Next steps:"
    echo "  1. Visit https://artifacthub.io/packages/search?user=Hoverhuang-er"
    echo "  2. Wait a few minutes for ArtifactHub to index your charts"
    echo "  3. Your charts should appear at: https://artifacthub.io/packages/search?repo=${REPO_NAME}"
elif [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Repository already exists and has been updated!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "ℹ️  Repository already exists"
    echo ""
    echo "If you don't see it in your dashboard, you may need to:"
    echo "  1. Log in to https://artifacthub.io"
    echo "  2. Go to Control Panel → Repositories"
    echo "  3. Click 'Claim Ownership' if the repository is listed"
elif [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo "❌ Authentication failed - please check your API credentials"
else
    echo "⚠️  Unexpected response from ArtifactHub API"
fi

echo ""
echo "📚 Documentation: https://artifacthub.io/docs/topics/repositories/"
