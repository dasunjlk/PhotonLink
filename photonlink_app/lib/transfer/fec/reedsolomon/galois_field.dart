/// Galois Field GF(2^8) with primitive polynomial 0x11D.
abstract final class GaloisField {
  static const int fieldSize = 256;
  static const int _generator = 0x11D;

  static final List<int> _exp = _buildExpTable();
  static final List<int> _log = _buildLogTable();

  static List<int> _buildExpTable() {
    final exp = List<int>.filled(512, 0);
    var x = 1;
    for (var i = 0; i < 255; i++) {
      exp[i] = x;
      x <<= 1;
      if (x & 0x100 != 0) {
        x ^= _generator;
      }
    }
    for (var i = 255; i < 512; i++) {
      exp[i] = exp[i - 255];
    }
    return exp;
  }

  static List<int> _buildLogTable() {
    final log = List<int>.filled(256, 0);
    for (var i = 0; i < 255; i++) {
      log[_exp[i]] = i;
    }
    return log;
  }

  static int add(int a, int b) => a ^ b;

  static int sub(int a, int b) => a ^ b;

  static int mul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _exp[_log[a] + _log[b]];
  }

  static int div(int a, int b) {
    if (b == 0) {
      throw ArgumentError('Division by zero in GF(256)');
    }
    if (a == 0) return 0;
    return _exp[(_log[a] - _log[b] + 255) % 255];
  }

  static int pow(int base, int exponent) {
    if (exponent == 0) return 1;
    if (base == 0) return 0;
    return _exp[(_log[base] * exponent) % 255];
  }

  static int inverse(int a) {
    if (a == 0) {
      throw ArgumentError('Cannot invert zero in GF(256)');
    }
    return _exp[255 - _log[a]];
  }
}
