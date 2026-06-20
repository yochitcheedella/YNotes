/// Centralised, reusable input-validation helpers for the YNote app.
/// These are used across all form validators to ensure consistent rules.
class InputValidator {
  /// Master password must be at least 8 characters and contain:
  ///   • One uppercase letter
  ///   • One digit
  /// Returns an error string, or null if valid.
  static String? masterPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }
    return null;
  }

  /// New password validator — same rules as master but also checks it
  /// differs from the current password.
  static String? newPassword(String? value, {String? currentPassword}) {
    final base = masterPassword(value);
    if (base != null) return base;
    if (currentPassword != null && value == currentPassword) {
      return 'New password must differ from the current password';
    }
    return null;
  }

  /// Recovery-key format: YN-XXXX-XXXX-XXXX (14 characters + dashes = 17 total)
  static String? recoveryKey(String? value) {
    if (value == null || value.isEmpty) return 'Recovery key is required';
    final cleaned = value.trim().toUpperCase();
    final pattern = RegExp(r'^YN-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Invalid key format. Expected: YN-XXXX-XXXX-XXXX';
    }
    return null;
  }

  /// Diary entry title must be 1–100 characters.
  static String? entryTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.trim().length > 100) return 'Title must be 100 characters or fewer';
    return null;
  }

  /// Diary content must not be empty.
  static String? entryContent(String? value) {
    if (value == null || value.trim().isEmpty) return 'Content cannot be empty';
    return null;
  }

  /// Decoy / general passwords: minimum 6 characters.
  static String? shortPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }
}
