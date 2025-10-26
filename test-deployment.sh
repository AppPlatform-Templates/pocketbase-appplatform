#!/bin/bash
#
# PocketBase App Platform Deployment Test Script
#
# This script tests a PocketBase deployment on DigitalOcean App Platform
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_URL="${1:-}"

if [ -z "$APP_URL" ]; then
    echo -e "${RED}Error: App URL is required${NC}"
    echo "Usage: $0 <app-url>"
    echo "Example: $0 https://pocketbase-abc123.ondigitalocean.app"
    exit 1
fi

# Remove trailing slash
APP_URL="${APP_URL%/}"

echo "=========================================="
echo "PocketBase Deployment Test"
echo "=========================================="
echo "App URL: $APP_URL"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
if curl -f -s "${APP_URL}/api/health" > /dev/null; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    exit 1
fi
echo ""

# Test 2: Admin UI
echo -e "${YELLOW}Test 2: Admin UI Accessibility${NC}"
if curl -f -s -o /dev/null "${APP_URL}/_/"; then
    echo -e "${GREEN}✓ Admin UI accessible${NC}"
else
    echo -e "${RED}✗ Admin UI not accessible${NC}"
    exit 1
fi
echo ""

# Test 3: API Endpoint
echo -e "${YELLOW}Test 3: API Endpoint${NC}"
if curl -f -s "${APP_URL}/api/" > /dev/null; then
    echo -e "${GREEN}✓ API endpoint accessible${NC}"
else
    echo -e "${RED}✗ API endpoint not accessible${NC}"
    exit 1
fi
echo ""

# Test 4: Response Time
echo -e "${YELLOW}Test 4: Response Time${NC}"
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "${APP_URL}/api/health")
if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
    echo -e "${GREEN}✓ Response time: ${RESPONSE_TIME}s (< 2s)${NC}"
else
    echo -e "${YELLOW}⚠ Response time: ${RESPONSE_TIME}s (>= 2s)${NC}"
fi
echo ""

# Test 5: HTTPS
echo -e "${YELLOW}Test 5: HTTPS/SSL${NC}"
if [[ "$APP_URL" == https://* ]]; then
    if curl -f -s -I "${APP_URL}" | grep -q "HTTP/"; then
        echo -e "${GREEN}✓ HTTPS is working${NC}"
    else
        echo -e "${RED}✗ HTTPS check failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Not using HTTPS${NC}"
fi
echo ""

# Test 6: Check for required headers
echo -e "${YELLOW}Test 6: Security Headers${NC}"
HEADERS=$(curl -s -I "${APP_URL}")

if echo "$HEADERS" | grep -q "X-Content-Type-Options"; then
    echo -e "${GREEN}✓ X-Content-Type-Options header present${NC}"
else
    echo -e "${YELLOW}⚠ X-Content-Type-Options header missing${NC}"
fi

if echo "$HEADERS" | grep -q "X-Frame-Options\|Content-Security-Policy"; then
    echo -e "${GREEN}✓ Frame protection headers present${NC}"
else
    echo -e "${YELLOW}⚠ Frame protection headers missing${NC}"
fi
echo ""

# Test 7: Collections API
echo -e "${YELLOW}Test 7: Collections API${NC}"
COLLECTIONS_RESPONSE=$(curl -s "${APP_URL}/api/collections")
if echo "$COLLECTIONS_RESPONSE" | grep -q "page\|items"; then
    echo -e "${GREEN}✓ Collections API responding${NC}"
else
    echo -e "${YELLOW}⚠ Collections API response unexpected (may need admin auth)${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Deployment Test Complete${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Access Admin UI: ${APP_URL}/_/"
echo "2. Create your admin account"
echo "3. Start creating collections"
echo ""
echo "API Documentation: https://pocketbase.io/docs/"
echo ""
