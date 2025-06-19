#!/bin/bash

# PayslipMax iOS MCP Startup Script
echo "🚀 Starting PayslipMax iOS MCP servers..."
echo "📁 Running from iOS project directory: $(pwd)"

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded"
else
    echo "❌ .env file not found. Please create one first."
    exit 1
fi

# Set iOS project path to current directory
export PAYSLIPMAX_IOS_PATH=$(pwd)
echo "📱 iOS project path set to: $PAYSLIPMAX_IOS_PATH"

# Create logs directory
mkdir -p logs

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Start MCP servers in background
cd mcp-servers

echo "🔧 Starting HTTP MCP server..."
nohup node mcp-http-server.js > ../logs/http-mcp.log 2>&1 &
HTTP_PID=$!
echo "   HTTP MCP PID: $HTTP_PID"

echo "📱 Starting iOS Development MCP server..."
nohup node ios-development-server.js > ../logs/ios-mcp.log 2>&1 &
IOS_PID=$!
echo "   iOS MCP PID: $IOS_PID"

echo "📚 Starting Documentation MCP server..."
nohup node documentation-generator.js > ../logs/docs-mcp.log 2>&1 &
DOCS_PID=$!
echo "   Docs MCP PID: $DOCS_PID"

cd ..

# Save PIDs for later shutdown
echo $HTTP_PID > .mcp-pids
echo $IOS_PID >> .mcp-pids
echo $DOCS_PID >> .mcp-pids

echo ""
echo "✅ MCP servers started successfully!"
echo "📄 Logs available in logs/ directory"
echo "🛑 Run './stop-mcps.sh' to stop all servers"
echo ""
echo "Next steps:"
echo "1. Update Cursor MCP settings to point to this iOS project"
echo "2. Test MCP functionality with iOS development tools" 