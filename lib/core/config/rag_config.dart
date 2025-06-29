import 'package:flutter/foundation.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';

class RagConfig {
  final String? openAiApiKey;
  final WeaviateConfig? weaviateConfig;
  final bool enableRag;
  final bool useMockServices;

  const RagConfig({
    this.openAiApiKey,
    this.weaviateConfig,
    this.enableRag = true,
    this.useMockServices = false,
  });

  bool get hasOpenAiKey => openAiApiKey != null && openAiApiKey!.isNotEmpty;
  bool get hasWeaviateConfig => weaviateConfig != null;
  bool get isFullyConfigured => hasOpenAiKey && hasWeaviateConfig;

  /// Create config from environment variables or default values
  factory RagConfig.fromEnvironment() {
    // In a real app, these would come from environment variables or secure storage
    // For now, we'll use default/placeholder values
    
    const openAiKey = String.fromEnvironment('OPENAI_API_KEY');
    const weaviateUrl = String.fromEnvironment('WEAVIATE_URL', defaultValue: 'http://localhost:8080');
    const weaviateApiKey = String.fromEnvironment('WEAVIATE_API_KEY');
    const enableRag = bool.fromEnvironment('ENABLE_RAG', defaultValue: true);
    const useMockServices = bool.fromEnvironment('USE_MOCK_RAG', defaultValue: false);

    WeaviateConfig? weaviateConfig;
    if (weaviateUrl.isNotEmpty) {
      weaviateConfig = WeaviateConfig(
        url: weaviateUrl,
        apiKey: weaviateApiKey.isNotEmpty ? weaviateApiKey : null,
      );
    }

    return RagConfig(
      openAiApiKey: openAiKey.isNotEmpty ? openAiKey : null,
      weaviateConfig: weaviateConfig,
      enableRag: enableRag,
      useMockServices: useMockServices,
    );
  }

  /// Create a development/demo config with mock services
  factory RagConfig.development() {
    return const RagConfig(
      enableRag: true,
      useMockServices: true,
    );
  }

  /// Create a production config that requires real API keys
  factory RagConfig.production({
    required String openAiApiKey,
    required WeaviateConfig weaviateConfig,
  }) {
    return RagConfig(
      openAiApiKey: openAiApiKey,
      weaviateConfig: weaviateConfig,
      enableRag: true,
      useMockServices: false,
    );
  }

  /// Disabled RAG config (fallback to simple responses only)
  factory RagConfig.disabled() {
    return const RagConfig(
      enableRag: false,
      useMockServices: false,
    );
  }

  void logConfiguration() {
    debugPrint('🔧 RAG Configuration:');
    debugPrint('  - RAG Enabled: $enableRag');
    debugPrint('  - Use Mock Services: $useMockServices');
    debugPrint('  - OpenAI API Key: ${hasOpenAiKey ? "✅ Configured" : "❌ Missing"}');
    debugPrint('  - Weaviate Config: ${hasWeaviateConfig ? "✅ Configured" : "❌ Missing"}');
    if (hasWeaviateConfig) {
      debugPrint('    - URL: ${weaviateConfig!.url}');
      debugPrint('    - API Key: ${weaviateConfig!.apiKey != null ? "✅ Set" : "❌ None"}');
    }
    debugPrint('  - Fully Configured: ${isFullyConfigured ? "✅ Yes" : "❌ No"}');
  }
} 