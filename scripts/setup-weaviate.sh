#!/bin/bash

# CritChat RAG Testing Setup Script
# This script sets up a local Weaviate instance for testing the character RAG system

set -e

echo "🚀 Setting up Weaviate for CritChat RAG testing..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   - macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "   - Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "   - Linux: https://docs.docker.com/engine/install/"
    exit 1
fi

echo "✅ Docker is installed"

# Check if port 8080 is available
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 8080 is already in use. Checking if it's Weaviate..."
    
    # Test if it's Weaviate
    if curl -s http://localhost:8080/v1/meta >/dev/null 2>&1; then
        echo "✅ Weaviate is already running on port 8080"
        echo ""
        echo "🔍 Testing Weaviate connection..."
        curl -s http://localhost:8080/v1/meta | jq '.version // "Connected successfully"' 2>/dev/null || echo "Connected"
        echo ""
        echo "✅ Weaviate is ready for testing!"
        exit 0
    else
        echo "❌ Port 8080 is occupied by another service. Please stop it first."
        exit 1
    fi
fi

echo "🐳 Starting Weaviate container..."

# Start Weaviate with optimized configuration for local development
docker run -d \
  --name weaviate-critchat \
  -p 8080:8080 \
  -p 50051:50051 \
  -e QUERY_DEFAULTS_LIMIT=25 \
  -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
  -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \
  -e DEFAULT_VECTORIZER_MODULE='none' \
  -e CLUSTER_HOSTNAME='node1' \
  -e LOG_LEVEL='info' \
  -e ENABLE_MODULES='text2vec-openai' \
  semitechnologies/weaviate:1.22.4

echo "⏳ Waiting for Weaviate to start..."

# Wait for Weaviate to be ready
for i in {1..30}; do
    if curl -s http://localhost:8080/v1/meta >/dev/null 2>&1; then
        echo "✅ Weaviate is ready!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Weaviate failed to start within 30 seconds"
        echo "🔍 Checking container logs:"
        docker logs weaviate-critchat --tail 20
        exit 1
    fi
    
    echo "   Attempt $i/30..."
    sleep 2
done

echo ""
echo "🔍 Weaviate Information:"
curl -s http://localhost:8080/v1/meta | jq '.version // "Unknown version"' 2>/dev/null || echo "Connected successfully"

echo ""
echo "✅ Weaviate setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Get an OpenAI API key from: https://platform.openai.com/api-keys"
echo "2. Edit lib/config/local_config.dart:"
echo "   - Replace 'YOUR_OPENAI_API_KEY_HERE' with your actual API key"
echo "   - Uncomment the configureForLocalTesting() call in setup()"
echo "3. Run the Flutter app: flutter run"
echo "4. Test the RAG system by creating a character and using @as commands!"
echo ""
echo "🛑 To stop Weaviate later: docker stop weaviate-critchat"
echo "🗑️  To remove Weaviate: docker rm weaviate-critchat" 