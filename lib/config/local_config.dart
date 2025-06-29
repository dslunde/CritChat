import 'package:flutter/foundation.dart';
import 'package:critchat/core/config/app_config.dart';

/// Local configuration for testing RAG features
/// 
/// IMPORTANT: This file is for local testing only.
/// Never commit actual API keys to version control!
/// 
/// To test the RAG system with real AI:
/// 1. Get an OpenAI API key from https://platform.openai.com/api-keys
/// 2. Set up Weaviate (see options below)
/// 3. Update the configuration in configureForTesting()
/// 4. Call LocalConfig.setup() in your main.dart

class LocalConfig {
  /// Set up configuration for local testing
  /// Call this in main.dart before runApp() to enable production AI testing
  static void setup() {
    // Uncomment and configure one of the options below:
    
    // Option 1: Local Weaviate with Docker (recommended for testing)
    // You'll need to run: docker run -p 8080:8080 semitechnologies/weaviate:latest
    // configureForLocalTesting();
    
    // Option 2: Weaviate Cloud (if you have a cloud instance)
    // configureForWeaviateCloud();
    
    // Option 3: Keep using mock services (default)
    // No configuration needed - system will use mock services
  }

  /// Configure for local Weaviate testing
  /// 
  /// Requirements:
  /// 1. OpenAI API key
  /// 2. Local Weaviate running on http://localhost:8080
  /// 
  /// To start local Weaviate:
  /// docker run -p 8080:8080 -p 50051:50051 \
  ///   -e QUERY_DEFAULTS_LIMIT=25 \
  ///   -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \
  ///   -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \
  ///   -e DEFAULT_VECTORIZER_MODULE='none' \
  ///   -e CLUSTER_HOSTNAME='node1' \
  ///   semitechnologies/weaviate:1.22.4
  static void configureForLocalTesting() {
    LocalTestingConfig.enableWithLocalWeaviate(
      openAiApiKey: 'YOUR_OPENAI_API_KEY_HERE', // Replace with your actual API key
      weaviateUrl: 'http://localhost:8080',
    );
  }

  /// Configure for Weaviate Cloud testing
  /// 
  /// Requirements:
  /// 1. OpenAI API key
  /// 2. Weaviate Cloud instance URL
  /// 3. Weaviate API key (if required by your instance)
  static void configureForWeaviateCloud() {
    LocalTestingConfig.enableWithWeaviateCloud(
      openAiApiKey: 'YOUR_OPENAI_API_KEY_HERE',        // Replace with your OpenAI API key
      weaviateUrl: 'https://your-cluster.weaviate.network', // Replace with your Weaviate URL
      weaviateApiKey: 'YOUR_WEAVIATE_API_KEY_HERE',     // Replace with your Weaviate API key (if needed)
    );
  }
}

/// Quick setup instructions for different configurations
class SetupInstructions {
  static const String openAiSetup = '''
🔑 OpenAI API Key Setup:
1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key and replace 'YOUR_OPENAI_API_KEY_HERE' in local_config.dart
4. Make sure you have credits in your OpenAI account
''';

  static const String localWeaviateSetup = '''
🐳 Local Weaviate Setup:
1. Install Docker on your machine
2. Run this command:
   docker run -p 8080:8080 -p 50051:50051 \\
     -e QUERY_DEFAULTS_LIMIT=25 \\
     -e AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true \\
     -e PERSISTENCE_DATA_PATH='/var/lib/weaviate' \\
     -e DEFAULT_VECTORIZER_MODULE='none' \\
     -e CLUSTER_HOSTNAME='node1' \\
     semitechnologies/weaviate:1.22.4

3. Wait for Weaviate to start (check http://localhost:8080/v1/meta)
4. Uncomment configureForLocalTesting() in LocalConfig.setup()
''';

  static const String cloudWeaviateSetup = '''
☁️ Weaviate Cloud Setup:
1. Go to https://console.weaviate.cloud/
2. Create a new cluster
3. Get your cluster URL and API key
4. Update configureForWeaviateCloud() with your details
5. Uncomment the call in LocalConfig.setup()
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