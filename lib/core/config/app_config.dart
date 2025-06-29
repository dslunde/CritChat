import 'package:flutter/foundation.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';
import 'package:critchat/core/config/rag_config.dart';

class AppConfig {
  // Environment flags
  static const bool kUseProductionAI = bool.fromEnvironment('USE_PRODUCTION_AI', defaultValue: false);
  static const bool kForceProductionAI = bool.fromEnvironment('FORCE_PRODUCTION_AI', defaultValue: false);
  
  // API Keys (should be set via environment or secure storage)
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String weaviateUrl = String.fromEnvironment('WEAVIATE_URL', defaultValue: 'http://localhost:8080');
  static const String weaviateApiKey = String.fromEnvironment('WEAVIATE_API_KEY', defaultValue: '');
  
  // Development overrides (for testing without environment variables)
  static String? _devOpenAiApiKey;
  static String? _devWeaviateUrl;
  static String? _devWeaviateApiKey;
  static bool? _devUseProductionAI;

  /// Set development API keys for testing (not recommended for production)
  static void setDevelopmentKeys({
    String? openAiKey,
    String? weaviateUrl,
    String? weaviateApiKey,
    bool? useProductionAI,
  }) {
    if (kDebugMode) {
      _devOpenAiApiKey = openAiKey;
      _devWeaviateUrl = weaviateUrl;
      _devWeaviateApiKey = weaviateApiKey;
      _devUseProductionAI = useProductionAI;
      debugPrint('🔧 Development AI configuration updated');
    }
  }

  /// Get effective OpenAI API key
  static String get effectiveOpenAiApiKey {
    if (kDebugMode && _devOpenAiApiKey != null) {
      return _devOpenAiApiKey!;
    }
    return openAiApiKey;
  }

  /// Get effective Weaviate URL
  static String get effectiveWeaviateUrl {
    if (kDebugMode && _devWeaviateUrl != null) {
      return _devWeaviateUrl!;
    }
    return weaviateUrl;
  }

  /// Get effective Weaviate API key
  static String get effectiveWeaviateApiKey {
    if (kDebugMode && _devWeaviateApiKey != null) {
      return _devWeaviateApiKey!;
    }
    return weaviateApiKey;
  }

  /// Should use production AI services
  static bool get shouldUseProductionAI {
    if (kForceProductionAI) return true;
    if (kDebugMode && _devUseProductionAI != null) {
      return _devUseProductionAI!;
    }
    return kUseProductionAI;
  }

  /// Check if OpenAI is configured
  static bool get hasOpenAiKey => effectiveOpenAiApiKey.isNotEmpty;

  /// Check if Weaviate is configured
  static bool get hasWeaviateConfig => effectiveWeaviateUrl.isNotEmpty;

  /// Get RAG configuration based on current settings
  static RagConfig getRagConfig() {
    if (!shouldUseProductionAI || !hasOpenAiKey || !hasWeaviateConfig) {
      debugPrint('🔧 Using development RAG configuration (mock services)');
      return RagConfig.development();
    }

    final weaviateConfig = WeaviateConfig(
      url: effectiveWeaviateUrl,
      apiKey: effectiveWeaviateApiKey.isNotEmpty ? effectiveWeaviateApiKey : null,
    );

    debugPrint('🔧 Using production RAG configuration');
    return RagConfig.production(
      openAiApiKey: effectiveOpenAiApiKey,
      weaviateConfig: weaviateConfig,
    );
  }

  /// Log current configuration (safe for production)
  static void logConfiguration() {
    debugPrint('🔧 App Configuration:');
    debugPrint('  - Use Production AI: $shouldUseProductionAI');
    debugPrint('  - OpenAI Configured: $hasOpenAiKey');
    debugPrint('  - Weaviate Configured: $hasWeaviateConfig');
    debugPrint('  - Weaviate URL: $effectiveWeaviateUrl');
    if (kDebugMode) {
      debugPrint('  - Development overrides active: ${_devOpenAiApiKey != null}');
    }
  }
}

/// Easy configuration preset for local testing
class LocalTestingConfig {
  static void enableWithLocalWeaviate({
    required String openAiApiKey,
    String weaviateUrl = 'http://localhost:8080',
  }) {
    AppConfig.setDevelopmentKeys(
      openAiKey: openAiApiKey,
      weaviateUrl: weaviateUrl,
      useProductionAI: true,
    );
    debugPrint('🚀 Local testing configuration enabled');
    debugPrint('   - Weaviate: $weaviateUrl');
    debugPrint('   - OpenAI: ${openAiApiKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
  }

  static void enableWithWeaviateCloud({
    required String openAiApiKey,
    required String weaviateUrl,
    String? weaviateApiKey,
  }) {
    AppConfig.setDevelopmentKeys(
      openAiKey: openAiApiKey,
      weaviateUrl: weaviateUrl,
      weaviateApiKey: weaviateApiKey,
      useProductionAI: true,
    );
    debugPrint('🚀 Cloud testing configuration enabled');
    debugPrint('   - Weaviate: $weaviateUrl');
    debugPrint('   - OpenAI: ${openAiApiKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}');
  }
} 