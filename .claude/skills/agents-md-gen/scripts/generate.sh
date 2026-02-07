#!/bin/bash
set -e

REPO_ROOT="${1:-.}"
OUTPUT_FILE="${REPO_ROOT}/AGENTS.md"

echo "=== AGENTS.md Generator ==="

# 1. Detect project info
echo "Inspecting repository..."
PROJECT_NAME=$(basename "$(cd "$REPO_ROOT" && pwd)")
HAS_PACKAGE_JSON=$( [ -f "$REPO_ROOT/package.json" ] && echo "yes" || echo "no" )
HAS_REQUIREMENTS=$( [ -f "$REPO_ROOT/requirements.txt" ] && echo "yes" || echo "no" )
HAS_DOCKERFILE=$( [ -f "$REPO_ROOT/Dockerfile" ] && echo "yes" || echo "no" )
HAS_K8S=$( [ -d "$REPO_ROOT/k8s" ] || [ -d "$REPO_ROOT/manifests" ] && echo "yes" || echo "no" )

# 2. Gather directory listing
DIRS=$(ls -d "$REPO_ROOT"/*/ 2>/dev/null | xargs -I{} basename {} | head -20)

# 3. Generate AGENTS.md
cat > "$OUTPUT_FILE" << AGENTS_EOF
# AGENTS.md

## Repository: ${PROJECT_NAME}

This file provides guidance for AI coding agents (Claude Code, Goose, Codex) working in this repository.

## Project Overview

- **Name**: ${PROJECT_NAME}
- **Type**: $([ "$HAS_K8S" = "yes" ] && echo "Cloud-native application" || echo "Application")

## Key Directories

$(for dir in $DIRS; do echo "- \`${dir}/\` — TODO: describe purpose"; done)

## Agent Rules

1. **Read before writing**: Always read existing files before modifying them.
2. **Small changes**: Make the smallest viable diff. Do not refactor unrelated code.
3. **No hardcoded secrets**: Use environment variables and Kubernetes Secrets.
4. **Validate changes**: Run tests and verification scripts after every change.
5. **Follow existing patterns**: Match the code style and structure already in use.

## Tools & Stack

$([ "$HAS_PACKAGE_JSON" = "yes" ] && echo "- **Node.js**: Check package.json for available scripts")
$([ "$HAS_REQUIREMENTS" = "yes" ] && echo "- **Python**: Check requirements.txt for dependencies")
$([ "$HAS_DOCKERFILE" = "yes" ] && echo "- **Docker**: Dockerfile available for containerization")
$([ "$HAS_K8S" = "yes" ] && echo "- **Kubernetes**: K8s manifests available for deployment")

## Standards

- Follow AAIF (Agentic AI Foundation) standards
- Use Skills with MCP Code Execution pattern where possible
- Prefer executable scripts over inline documentation

## For Claude Code

- Use \`Bash\` tool for command execution
- Use \`Write\` tool for file creation
- Use \`Edit\` tool for modifications
- Capture and validate command outputs

## For Goose

- Use \`toolkit.run_shell()\` for bash commands
- Use \`toolkit.write_file()\` for file creation
- Use \`toolkit.read_file()\` for verification
- Check return codes for all commands
AGENTS_EOF

echo "✓ AGENTS.md generated at ${OUTPUT_FILE}"
echo "  Review and customize the TODO items for your project."
