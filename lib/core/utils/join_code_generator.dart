import 'dart:math';

class JoinCodeGenerator {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _codeLength = 6;

  /// Generates a random join code in the format CCC-CCC
  /// where C is an alphanumeric character (A-Z, 0-9)
  static String generate() {
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < _codeLength; i++) {
      if (i == 3) {
        buffer.write('-');
      }
      buffer.write(_chars[random.nextInt(_chars.length)]);
    }

    return buffer.toString();
  }

  /// Validates if a join code has the correct format
  static bool isValidFormat(String joinCode) {
    final pattern = RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{3}$');
    return pattern.hasMatch(joinCode);
  }

  /// Normalizes a join code to uppercase and proper format
  static String normalize(String joinCode) {
    return joinCode.toUpperCase().replaceAll(' ', '');
  }
}
