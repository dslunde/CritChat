import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:critchat/core/config/app_config.dart';

/// Local configuration for testing RAG features
/// 
/// SAFE SETUP: This file reads API keys from .env.local (which is gitignored)
/// 
/// To test the RAG system with real AI:
/// 1. Copy env.local.example to .env.local
/// 2. Edit .env.local with your OpenAI API key
/// 3. Run: ./scripts/setup-weaviate.sh
/// 4. Run: flutter run

class LocalConfig {
  /// Set up configuration for local testing
  /// Call this in main.dart before runApp() to enable production AI testing
  static Future<void> setup() async {
    await _loadEnvironmentConfiguration();
  }

  /// Try to load configuration from .env.local
  static Future<void> _loadEnvironmentConfiguration() async {
    try {
      // Load .env.local file
      await dotenv.load(fileName: '.env.local');
      
      // Check if production AI is enabled
      final useProductionAI = dotenv.env['USE_PRODUCTION_AI']?.toLowerCase() == 'true';
      
      if (!useProductionAI) {
        debugPrint('📝 Using mock RAG services (USE_PRODUCTION_AI=false)');
        _printSetupInstructions();
        return;
      }

      // Get API keys from environment
      final openAiApiKey = dotenv.env['OPENAI_API_KEY'];
      final weaviateUrl = dotenv.env['WEAVIATE_URL'] ?? 'http://localhost:8080';
      final weaviateApiKey = dotenv.env['WEAVIATE_API_KEY'];

      // Validate required fields
      if (openAiApiKey == null || openAiApiKey.isEmpty || openAiApiKey == 'your_openai_api_key_here') {
        debugPrint('⚠️ Missing or placeholder OpenAI API key in .env.local');
        _printSetupInstructions();
        return;
      }

      // Configure based on Weaviate setup
      if (weaviateUrl.contains('localhost')) {
        LocalTestingConfig.enableWithLocalWeaviate(
          openAiApiKey: openAiApiKey,
          weaviateUrl: weaviateUrl,
        );
        debugPrint('✅ Configured RAG with local Weaviate');
      } else {
        LocalTestingConfig.enableWithWeaviateCloud(
          openAiApiKey: openAiApiKey,
          weaviateUrl: weaviateUrl,
          weaviateApiKey: weaviateApiKey,
        );
        debugPrint('✅ Configured RAG with Weaviate Cloud');
      }
      
    } catch (e) {
      // .env.local doesn't exist or has errors - use mock services
      debugPrint('📝 Using mock RAG services (.env.local not found)');
      debugPrint('   Error: ${e.toString()}');
      _printSetupInstructions();
    }
  }

  /// Print setup instructions for RAG testing
  static void _printSetupInstructions() {
    if (kDebugMode) {
      debugPrint('');
      debugPrint('🤖 To enable AI-powered character responses:');
      debugPrint('');
      debugPrint('   Step 1: Copy the example file');
      debugPrint('   cp env.local.example .env.local');
      debugPrint('');
      debugPrint('   Step 2: Edit .env.local with your OpenAI API key');
      debugPrint('   (Get one from: https://platform.openai.com/api-keys)');
      debugPrint('');
      debugPrint('   Step 3: Set up local Weaviate');
      debugPrint('   ./scripts/setup-weaviate.sh');
      debugPrint('');
      debugPrint('   Step 4: Restart the app');
      debugPrint('   flutter run');
      debugPrint('');
      debugPrint('💡 Currently using mock responses for @as commands');
      debugPrint('');
    }
  }
}

/// Quick setup instructions for different configurations
class SetupInstructions {
  static const String openAiSetup = '''
🔑 OpenAI API Key Setup:
1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy env.local.example to .env.local
4. Edit .env.local with your actual API key
5. Make sure you have credits in your OpenAI account
''';

  static const String localWeaviateSetup = '''
🐳 Local Weaviate Setup:
1. Run the setup script: ./scripts/setup-weaviate.sh
2. Wait for Weaviate to start (check http://localhost:8080/v1/meta)
3. Your .env.local should be configured for local testing
''';

  static const String cloudWeaviateSetup = '''
☁️ Weaviate Cloud Setup:
1. Go to https://console.weaviate.cloud/
2. Create a new cluster
3. Get your cluster URL and API key
4. Edit .env.local with your Weaviate cloud details
5. Update WEAVIATE_URL and WEAVIATE_API_KEY
''';

  static const String testing = '''
🧪 Testing the RAG System:
1. Complete setup above
2. Run the app: flutter run
3. Create a character with personality details
4. Add memories using the character memory widget
5. Test @as commands in fellowship chats:
   - @as Gandalf "Welcome to my realm!"
   - @as "Sir Reginald" "Good day to you all!"
6. Watch for contextual AI responses!
''';

  static void printAll() {
    debugPrint(openAiSetup);
    debugPrint(localWeaviateSetup);
    debugPrint(cloudWeaviateSetup);
    debugPrint(testing);
  }
} 