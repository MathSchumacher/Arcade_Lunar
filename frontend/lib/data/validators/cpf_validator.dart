/// CPF Validator for Brazilian ID
/// Uses the official Luhn-like algorithm for CPF validation
class CpfValidator {
  /// Validates a CPF number
  /// Returns true if valid, false otherwise
  static bool validate(String cpf) {
    // Remove non-digits
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    
    // Must have 11 digits
    if (cpf.length != 11) return false;
    
    // Check for known invalid patterns (all same digits)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    
    // Convert to list of integers
    List<int> digits = cpf.split('').map(int.parse).toList();
    
    // Validate first check digit
    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += digits[i] * (10 - i);
    }
    int check1 = (sum1 * 10) % 11;
    if (check1 == 10) check1 = 0;
    if (check1 != digits[9]) return false;
    
    // Validate second check digit
    int sum2 = 0;
    for (int i = 0; i < 10; i++) {
      sum2 += digits[i] * (11 - i);
    }
    int check2 = (sum2 * 10) % 11;
    if (check2 == 10) check2 = 0;
    
    return check2 == digits[10];
  }
  
  /// Format CPF with dots and dash: 123.456.789-00
  static String format(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }
  
  /// Remove formatting from CPF
  static String clean(String cpf) {
    return cpf.replaceAll(RegExp(r'\D'), '');
  }
}
