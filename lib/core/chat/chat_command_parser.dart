class ChatCommandParser {
  static const String asCommand = '@as';
  
  static bool isAsCommand(String content) {
    return content.trim().toLowerCase().startsWith('$asCommand ');
  }
  
  static AsCommandData? parseAsCommand(String content) {
    final trimmed = content.trim();
    if (!isAsCommand(trimmed)) return null;
    
    // Remove "@as " (4 characters)
    final remainder = trimmed.substring(4);
    
    // Handle quoted character names: @as "Sir Reginald" Hello there!
    if (remainder.startsWith('"')) {
      final endQuoteIndex = remainder.indexOf('"', 1);
      if (endQuoteIndex == -1) return null; // Invalid syntax - missing closing quote
      
      final characterName = remainder.substring(1, endQuoteIndex);
      final messageStart = endQuoteIndex + 1;
      
      if (messageStart >= remainder.length) return null; // No message after character name
      final message = remainder.substring(messageStart).trim();
      
      if (characterName.isEmpty || message.isEmpty) return null;
      
      return AsCommandData(characterName: characterName, message: message);
    }
    
    // Handle unquoted character names: @as Gandalf Hello there!
    final spaceIndex = remainder.indexOf(' ');
    if (spaceIndex == -1) return null; // No message part
    
    final characterName = remainder.substring(0, spaceIndex);
    final message = remainder.substring(spaceIndex + 1).trim();
    
    if (characterName.isEmpty || message.isEmpty) return null;
    
    return AsCommandData(characterName: characterName, message: message);
  }
  
  static List<String> suggestCharacterCommands(String input, List<String> characterNames) {
    final lower = input.toLowerCase();
    
    // Show all characters when typing @, @a, or @as
    if (lower == '@' || lower == '@a' || lower == '@as') {
      return characterNames.map((name) => '@as $name ').toList();
    }
    
    // Filter characters based on partial input
    if (lower.startsWith('@as ')) {
      final remainder = input.substring(4).toLowerCase();
      
      // Handle quoted names in progress
      if (remainder.startsWith('"')) {
        final quotedPart = remainder.substring(1);
        return characterNames
            .where((name) => name.toLowerCase().startsWith(quotedPart))
            .map((name) => '@as "$name" ')
            .toList();
      }
      
      // Handle unquoted names
      return characterNames
          .where((name) => name.toLowerCase().startsWith(remainder))
          .map((name) => name.contains(' ') ? '@as "$name" ' : '@as $name ')
          .toList();
    }
    
    return [];
  }
  
  static bool isPartialAsCommand(String input) {
    final lower = input.toLowerCase();
    return lower == '@' || lower == '@a' || lower == '@as' || lower.startsWith('@as ');
  }
  
  static String getCharacterNameFromCommand(String input) {
    final commandData = parseAsCommand(input);
    return commandData?.characterName ?? '';
  }
  
  static String formatAsCommand(String characterName, String message) {
    final needsQuotes = characterName.contains(' ');
    return needsQuotes 
        ? '@as "$characterName" $message'
        : '@as $characterName $message';
  }
}

class AsCommandData {
  final String characterName;
  final String message;
  
  const AsCommandData({
    required this.characterName,
    required this.message,
  });
  
  @override
  String toString() => '@as $characterName $message';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsCommandData &&
        other.characterName == characterName &&
        other.message == message;
  }
  
  @override
  int get hashCode => characterName.hashCode ^ message.hashCode;
}

// Helper class for command validation results
class CommandValidationResult {
  final bool isValid;
  final String? error;
  
  const CommandValidationResult({
    required this.isValid,
    this.error,
  });
  
  const CommandValidationResult.valid() : isValid = true, error = null;
  const CommandValidationResult.invalid(this.error) : isValid = false;
}

class ChatCommandValidator {
  static CommandValidationResult validateAsCommand(String input) {
    if (!ChatCommandParser.isAsCommand(input)) {
      return const CommandValidationResult.invalid('Not an @as command');
    }
    
    final commandData = ChatCommandParser.parseAsCommand(input);
    if (commandData == null) {
      return const CommandValidationResult.invalid(
        'Invalid @as command format. Use: @as <character> <message>'
      );
    }
    
    if (commandData.characterName.trim().isEmpty) {
      return const CommandValidationResult.invalid('Character name cannot be empty');
    }
    
    if (commandData.characterName.length > 30) {
      return const CommandValidationResult.invalid('Character name cannot exceed 30 characters');
    }
    
    if (commandData.message.trim().isEmpty) {
      return const CommandValidationResult.invalid('Message cannot be empty');
    }
    
    if (commandData.message.length > 1000) {
      return const CommandValidationResult.invalid('Message cannot exceed 1000 characters');
    }
    
    return const CommandValidationResult.valid();
  }
} 