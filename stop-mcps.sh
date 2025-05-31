#!/bin/bash

echo "🛑 Stopping PayslipMax MCP servers..."

if [ -f ".mcp-pids" ]; then
    while read pid; do
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            echo "✅ Stopped process $pid"
        else
            echo "⚠️  Process $pid was not running"
        fi
    done < .mcp-pids
    
    rm .mcp-pids
    echo ""
    echo "✅ All MCP servers stopped successfully"
else
    echo "❌ No running MCP servers found (.mcp-pids file not found)"
fi 