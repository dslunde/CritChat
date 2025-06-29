# 🤖 CritChat RAG System Setup Guide

This guide will help you set up the complete RAG (Retrieval-Augmented Generation) system for CritChat, enabling AI-powered character interactions with memory and context awareness.

## 🎯 What You'll Get

After setup, you'll have:
- **AI-powered character responses** using OpenAI GPT-4o-mini
- **Character memory system** with automatic vectorization
- **Context-aware interactions** that remember past conversations
- **Seamless @as commands** like `@as Gandalf "Welcome to my realm!"`

## 🚀 Quick Setup (Recommended)

### Option 1: Automated Setup with Docker

1. **Run the setup script:**
   ```bash
   chmod +x scripts/setup-weaviate.sh
   ./scripts/setup-weaviate.sh
   ```

2. **Get OpenAI API Key:**
   - Go to [OpenAI API Keys](https://platform.openai.com/api-keys)
   - Create a new API key
   - Make sure you have credits in your account

3. **Configure the app (SECURE - No git commits needed!):**
   ```bash
   # Copy the example environment file
   cp env.local.example .env.local
   
   # Edit .env.local with your API key
   # Replace 'your_openai_api_key_here' with your actual key
   ```

4. **Test it:**
   ```bash
   flutter run
   ```

### Option 2: Manual Docker Setup

1. **Start Weaviate:**
   ```bash
   docker run -d \
     --name weaviate-critchat \
     -p 8080:8080 \
     -p 50051:50051 \
     -e QUERY_DEFAULTS_LIMIT=25 \
     -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
     -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \
     -e DEFAULT_VECTORIZER_MODULE='none' \
     -e CLUSTER_HOSTNAME='node1' \
     semitechnologies/weaviate:1.22.4
   ```

2. **Verify Weaviate is running:**
   ```bash
   curl http://localhost:8080/v1/meta
   ```

3. **Configure as above** (steps 2-4 from Option 1)

## 🌐 Cloud Setup (Alternative)

### Weaviate Cloud Setup

1. **Create Weaviate Cloud instance:**
   - Go to [Weaviate Console](https://console.weaviate.cloud/)
   - Create a new cluster
   - Get your cluster URL and API key

2. **Configure for cloud:**
   ```bash
   # Copy the example environment file
   cp env.local.example .env.local
   
   # Edit .env.local:
   # - Replace OpenAI API key
   # - Update WEAVIATE_URL with your cloud instance URL
   # - Add WEAVIATE_API_KEY with your cloud API key
   ```

## 🧪 Testing the RAG System

### 1. Create a Character
- Open the app and create a character with personality details
- Add a rich backstory, personality traits, and speech patterns

### 2. Add Character Memories
- Use the character memory widget to add information:
  - **Session notes:** "In our last adventure, we fought a dragon"
  - **NPC interactions:** "I met a mysterious shopkeeper named Gareth"
  - **Character feelings:** "I felt nervous about the dungeon"
  - **Background details:** "I grew up in a small village"

### 3. Test @as Commands
Try these commands in fellowship chats:
- `@as Gandalf "Welcome, young adventurers!"`
- `@as "Sir Reginald" "Good day to you all!"`
- `@as Elrond "The path ahead is perilous"`

### 4. Watch the Magic ✨
- Characters will respond based on their personality
- Relevant memories will influence responses
- Recent chat context provides conversational awareness

## 🔧 Configuration Options

### Environment Variables (Production)
```bash
export OPENAI_API_KEY="your-openai-key"
export WEAVIATE_URL="http://localhost:8080"
export USE_PRODUCTION_AI=true
```

### Development Configuration
```bash
# Copy example and edit with your keys
cp env.local.example .env.local

# Example .env.local content:
# OPENAI_API_KEY=your-actual-openai-key
# WEAVIATE_URL=http://localhost:8080
# USE_PRODUCTION_AI=true
```

## 🐛 Troubleshooting

### Weaviate Issues
```bash
# Check if Weaviate is running
curl http://localhost:8080/v1/meta

# View container logs
docker logs weaviate-critchat

# Restart Weaviate
docker restart weaviate-critchat
```

### OpenAI Issues
- Verify your API key is correct
- Check you have credits in your OpenAI account
- Monitor API usage at [OpenAI Usage](https://platform.openai.com/usage)

### App Configuration Issues
- Check the debug console for configuration logs
- Look for "🔧 App Configuration" messages
- Verify both OpenAI and Weaviate show as configured

### Memory/Embedding Issues
- Check Weaviate schema initialization in logs
- Verify character memories are being stored
- Test vector search functionality

## 💰 Cost Considerations

### OpenAI Pricing (as of November 2024)
- **Embeddings (text-embedding-3-small):** ~$0.00002 per 1K tokens
- **Chat (GPT-4o-mini):** ~$0.00015 per 1K input tokens, ~$0.0006 per 1K output tokens

### Typical Usage
- **Character memory (1000 words):** ~$0.003
- **Character response:** ~$0.001-0.002 per response
- **Very affordable for testing and personal use**

## 🔒 Security Notes

### For Development
- ✅ **SECURE BY DESIGN:** API keys are stored in `.env.local` which is automatically gitignored
- ✅ **NO GIT RISK:** Your actual API keys are never committed to version control
- ✅ **SIMPLE SETUP:** Just copy `env.local.example` and edit with your keys
- Use `.env.local` for your actual keys (never commit this file)

### For Production
- Use environment variables or secure key management
- Consider rate limiting and usage monitoring
- Implement proper API key rotation

## 🎛️ Advanced Configuration

### Custom Weaviate Setup
```bash
# With custom modules
docker run -d \
  --name weaviate-critchat \
  -p 8080:8080 \
  -e ENABLE_MODULES='text2vec-openai,backup-filesystem' \
  -e BACKUP_FILESYSTEM_PATH='/var/lib/weaviate/backups' \
  semitechnologies/weaviate:1.22.4
```

### Production Monitoring
- Monitor OpenAI API usage and costs
- Set up Weaviate health checks
- Implement error alerting for AI service failures

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review app logs for detailed error messages
3. Verify all services are running and configured correctly
4. Test individual components (Weaviate connection, OpenAI API)

## 🎉 Success!

Once configured, you'll have a fully functional AI-powered character system that:
- Remembers character experiences and interactions
- Generates contextually appropriate responses
- Maintains consistent character personalities
- Provides an immersive TTRPG chat experience

**Your characters are now powered by AI! 🤖✨** 