class HashUtils {
  static String generateHash(String input) {
    var hashCode = input.hashCode;
    return hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }
}
