#!/bin/bash
# Easy setup script for Claude-Gemini MCP Server
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Claude-Gemini MCP Server Setup${NC}"
echo ""

# Check if API key was provided
API_KEY="$1"
if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ Please provide your Gemini API key${NC}"
    echo "Usage: ./setup.sh YOUR_GEMINI_API_KEY"
    echo ""
    echo "Get a free API key at: https://aistudio.google.com/apikey"
    exit 1
fi

# Check Python version
echo "📋 Checking requirements..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is required but not installed.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✅ Python $PYTHON_VERSION found"

# Check for venv module
if ! python3 -m venv --help &> /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  python3-venv not found.${NC}"
    echo "Install it with: sudo apt install python3-venv python3-full"
    exit 1
fi

# Check Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${RED}❌ Claude Code CLI not found. Please install it first:${NC}"
    echo "npm install -g @anthropic-ai/claude-code"
    exit 1
fi
echo "✅ Claude Code CLI found"

# Create directory
echo ""
echo "📁 Creating MCP server directory..."
mkdir -p ~/.claude-mcp-servers/gemini-collab

# Create or use existing virtual environment
echo "🐍 Setting up Python virtual environment..."
VENV_PATH="$HOME/.claude-mcp-servers/gemini-collab/venv"

if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "✅ Virtual environment created"
else
    echo "✅ Using existing virtual environment"
fi

# Copy server file
echo "📋 Installing server..."
cp server.py ~/.claude-mcp-servers/gemini-collab/

# Set environment variable persistently
echo "🔧 Setting up persistent environment variable..."

# Detect shell and appropriate profile file
if [ -n "$ZSH_VERSION" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    else
        PROFILE_FILE="$HOME/.bash_profile"
    fi
else
    # Fallback to .profile for other shells
    PROFILE_FILE="$HOME/.profile"
fi

# Remove any existing CLAUDE_GEMINI_MCP_API_KEY entries
sed -i.bak '/^export CLAUDE_GEMINI_MCP_API_KEY=/d' "$PROFILE_FILE" 2>/dev/null || true
rm -f "$PROFILE_FILE.bak" 2>/dev/null || true

# Add the new API key
echo "export CLAUDE_GEMINI_MCP_API_KEY=\"$API_KEY\"" >> "$PROFILE_FILE"

echo "✅ API key added to $PROFILE_FILE"

# Install Python dependencies in virtual environment
echo ""
echo "📦 Installing Python dependencies..."

# Always use the venv Python (regardless of whether user activated it)
PYTHON_PATH="$VENV_PATH/bin/python3"

# Upgrade pip and install dependencies
"$PYTHON_PATH" -m pip install --upgrade pip --quiet
"$PYTHON_PATH" -m pip install google-generativeai --quiet

echo "✅ Dependencies installed in virtual environment"

# Remove any existing MCP configuration
echo ""
echo "🔧 Configuring Claude Code..."
claude mcp remove gemini-collab 2>/dev/null || true

# Add MCP server with venv Python path
claude mcp add --scope user gemini-collab "$PYTHON_PATH" ~/.claude-mcp-servers/gemini-collab/server.py

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "🎉 You can now use Gemini in Claude Code from any directory!"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Reload your shell to activate the API key:${NC}"
echo "  source $PROFILE_FILE"
echo ""
echo "Try it out:"
echo "  1. Run: claude"
echo "  2. Type: /mcp (should show gemini-collab connected)"
echo "  3. Use: mcp__gemini-collab__ask_gemini"
echo "         prompt: \"Hello Gemini!\""
echo ""
echo "Available tools:"
echo "  • mcp__gemini-collab__ask_gemini"
echo "  • mcp__gemini-collab__gemini_code_review"
echo "  • mcp__gemini-collab__gemini_brainstorm"
echo ""
echo "Enjoy! 🚀"
