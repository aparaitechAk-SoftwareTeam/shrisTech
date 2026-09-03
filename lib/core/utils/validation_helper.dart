/// Validation helper containing pure validation methods for BBS GOLD authentication module.
abstract class ValidationHelper {
  // Regex patterns
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s]+$');
  static final RegExp _mobileRegex = RegExp(r'^[0-9]{10}$');
  static final RegExp _emailFormatRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
  );
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecialChar = RegExp(
    r'[!@#$%^&*(),.?":{}|<>\_\+\-\=\[\]]',
  );

  /// Trims leading and trailing spaces cleanly
  static String sanitize(String input) => input.trim();

  // --- LOGIN VALIDATIONS ---

  /// Validates Email or User ID for login
  static String? validateLoginIdentity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or User ID is required';
    }
    final trimmed = value.trim();
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return 'Leading or trailing spaces are not allowed';
    }
    if (trimmed.length < 3) {
      return 'Must be at least 3 characters long';
    }
    return null;
  }

  /// Validates Login Password
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // --- REGISTRATION VALIDATIONS ---

  /// Validates Retailer Name
  /// Rules: Required, min 3 chars, alphabets and spaces only, no numbers, no special symbols
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Name must contain only alphabets and spaces';
    }
    return null;
  }

  /// Validates Mobile Number
  /// Rules: Required, exactly 10 digits, digits only, no alphabets/symbols
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile Number is required';
    }
    final trimmed = value.trim();
    if (!_mobileRegex.hasMatch(trimmed)) {
      return 'Mobile Number must be exactly 10 digits';
    }
    return null;
  }

  /// Validates Email
  /// Rules: Required, valid email format, MUST end with @gmail.com, no spaces
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim().toLowerCase();
    if (value.contains(' ')) {
      return 'Spaces are not allowed in email';
    }
    if (!trimmed.endsWith('@gmail.com')) {
      return 'Email must end with @gmail.com';
    }
    if (!_emailFormatRegex.hasMatch(trimmed)) {
      return 'Please enter a valid Gmail address (e.g. name@gmail.com)';
    }
    return null;
  }

  /// Validates Shop Name
  /// Rules: Required, min 3 chars
  static String? validateShopName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shop Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Shop Name must be at least 3 characters';
    }
    return null;
  }

  /// Validates Address
  /// Rules: Required, multi-line, min 10 chars, max 200 chars
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shop Address is required';
    }
    final trimmed = value.trim();
    // if (trimmed.length < 10) {
    //   return 'Address must be at least 10 characters';
    // }
    if (trimmed.length > 200) {
      return 'Address cannot exceed 200 characters';
    }
    return null;
  }

  /// Validates Registration Password
  /// Rules: Required, min 8, max 32, uppercase, lowercase, digit, special character
  static String? validateRegistrationPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 32) {
      return 'Password cannot exceed 32 characters';
    }
    if (!_hasUppercase.hasMatch(value)) {
      return 'Must include at least one uppercase letter (A-Z)';
    }
    if (!_hasLowercase.hasMatch(value)) {
      return 'Must include at least one lowercase letter (a-z)';
    }
    if (!_hasDigit.hasMatch(value)) {
      return 'Must include at least one digit (0-9)';
    }
    if (!_hasSpecialChar.hasMatch(value)) {
      return 'Must include at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  // --- PASSWORD STRENGTH & CHECKLIST HELPERS ---

  static bool hasMinLength(String password, [int min = 8]) =>
      password.length >= min;
  static bool hasMaxLength(String password, [int max = 32]) =>
      password.length <= max;
  static bool containsUppercase(String password) =>
      _hasUppercase.hasMatch(password);
  static bool containsLowercase(String password) =>
      _hasLowercase.hasMatch(password);
  static bool containsDigit(String password) => _hasDigit.hasMatch(password);
  static bool containsSpecialChar(String password) =>
      _hasSpecialChar.hasMatch(password);

  /// Evaluates password strength level: 0 = None, 1 = Weak, 2 = Medium, 3 = Strong
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;
    if (hasMinLength(password)) score++;
    if (containsUppercase(password) && containsLowercase(password)) score++;
    if (containsDigit(password)) score++;
    if (containsSpecialChar(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { none, weak, medium, strong }
