import 'dart:typed_data';

import '../erasure_code.dart';
import 'galois_field.dart';

/// Systematic Reed-Solomon erasure codec over GF(256).
///
/// Data symbols 0..k-1 are transmitted as-is; parity symbols k..k+m-1
/// are computed from the parity generator matrix.
class ReedSolomonCodec implements ErasureCode {
  const ReedSolomonCodec();

  @override
  List<Uint8List> encodeBlock({
    required List<Uint8List> dataSymbols,
    required int parityCount,
    required int symbolLength,
  }) {
    final k = dataSymbols.length;
    final m = parityCount;
    if (k < 1 || m < 1) {
      throw ArgumentError('dataCount and parityCount must be >= 1');
    }
    if (k + m > 255) {
      throw ArgumentError('k + m must be <= 255 for GF(256)');
    }

    final parityGen = _parityGeneratorMatrix(k, m);
    final parity = List.generate(m, (_) => Uint8List(symbolLength));

    for (var row = 0; row < m; row++) {
      for (var b = 0; b < symbolLength; b++) {
        var sum = 0;
        for (var col = 0; col < k; col++) {
          sum = GaloisField.add(
            sum,
            GaloisField.mul(parityGen[row][col], dataSymbols[col][b]),
          );
        }
        parity[row][b] = sum;
      }
    }

    return parity;
  }

  @override
  List<Uint8List>? decodeBlock({
    required int dataCount,
    required int parityCount,
    required int symbolLength,
    required List<int> erasures,
    required Map<int, Uint8List> available,
  }) {
    final k = dataCount;
    final m = parityCount;
    final erasureSet = erasures.toSet();

    // Fast path: all data present.
    var allDataPresent = true;
    for (var i = 0; i < k; i++) {
      if (erasureSet.contains(i) || !available.containsKey(i)) {
        allDataPresent = false;
        break;
      }
    }
    if (allDataPresent) {
      return List.generate(k, (i) => Uint8List.fromList(available[i]!));
    }

    if (available.length < k) return null;
    if (erasures.length > m) return null;

    final parityGen = _parityGeneratorMatrix(k, m);

    // Build k linear equations for k unknowns (data bytes at each position).
    final equations = <_Equation>[];

    for (var i = 0; i < k; i++) {
      if (!erasureSet.contains(i) && available.containsKey(i)) {
        equations.add(_Equation.direct(i, available[i]!));
      }
    }

    for (var p = 0; p < m; p++) {
      final idx = k + p;
      if (!erasureSet.contains(idx) && available.containsKey(idx)) {
        equations.add(
          _Equation.parity(
            parityGen[p],
            available[idx]!,
          ),
        );
      }
    }

    if (equations.length < k) return null;

    // Use first k independent equations.
    final selected = equations.take(k).toList();
    final recovered = List.generate(k, (_) => Uint8List(symbolLength));

    for (var b = 0; b < symbolLength; b++) {
      final matrix = List.generate(k, (_) => List<int>.filled(k, 0));
      final values = List<int>.filled(k, 0);

      for (var r = 0; r < k; r++) {
        final eq = selected[r];
        switch (eq) {
          case _DirectEquation(:final index, :final value):
            matrix[r][index] = 1;
            values[r] = value[b];
          case _ParityEquation(:final coeffs, :final value):
            for (var c = 0; c < k; c++) {
              matrix[r][c] = coeffs[c];
            }
            values[r] = value[b];
        }
      }

      final inverse = _invertMatrix(matrix);
      if (inverse == null) return null;

      for (var col = 0; col < k; col++) {
        var sum = 0;
        for (var row = 0; row < k; row++) {
          sum = GaloisField.add(
            sum,
            GaloisField.mul(inverse[col][row], values[row]),
          );
        }
        recovered[col][b] = sum;
      }
    }

    return recovered;
  }

  static List<List<int>> _vandermondeMatrix(int n, int k) {
    return List.generate(n, (i) {
      final eval = i + 1;
      return List.generate(k, (j) => GaloisField.pow(eval, j));
    });
  }

  static List<List<int>> _parityGeneratorMatrix(int k, int m) {
    final v = _vandermondeMatrix(k + m, k);
    final top = v.sublist(0, k);
    final bottom = v.sublist(k, k + m);
    final invTop = _invertMatrix(top);
    if (invTop == null) {
      throw StateError('Singular Vandermonde top matrix');
    }
    return _multiplyMatrices(bottom, invTop);
  }

  static List<List<int>> _multiplyMatrices(
    List<List<int>> a,
    List<List<int>> b,
  ) {
    final rows = a.length;
    final cols = b[0].length;
    final inner = b.length;
    return List.generate(rows, (i) {
      return List.generate(cols, (j) {
        var sum = 0;
        for (var t = 0; t < inner; t++) {
          sum = GaloisField.add(sum, GaloisField.mul(a[i][t], b[t][j]));
        }
        return sum;
      });
    });
  }

  static List<List<int>>? _invertMatrix(List<List<int>> matrix) {
    final n = matrix.length;
    final aug = List.generate(n, (i) {
      final row = List<int>.from(matrix[i]);
      for (var j = 0; j < n; j++) {
        row.add(i == j ? 1 : 0);
      }
      return row;
    });

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      while (pivotRow < n && aug[pivotRow][col] == 0) {
        pivotRow++;
      }
      if (pivotRow == n) return null;

      if (pivotRow != col) {
        final tmp = aug[col];
        aug[col] = aug[pivotRow];
        aug[pivotRow] = tmp;
      }

      final invPivot = GaloisField.inverse(aug[col][col]);
      for (var j = 0; j < 2 * n; j++) {
        aug[col][j] = GaloisField.mul(aug[col][j], invPivot);
      }

      for (var row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = aug[row][col];
        if (factor == 0) continue;
        for (var j = 0; j < 2 * n; j++) {
          aug[row][j] = GaloisField.sub(
            aug[row][j],
            GaloisField.mul(factor, aug[col][j]),
          );
        }
      }
    }

    return List.generate(n, (i) => aug[i].sublist(n, 2 * n));
  }
}

sealed class _Equation {
  const _Equation();
  factory _Equation.direct(int index, Uint8List value) =
      _DirectEquation;
  factory _Equation.parity(List<int> coeffs, Uint8List value) =
      _ParityEquation;
}

final class _DirectEquation extends _Equation {
  const _DirectEquation(this.index, this.value);
  final int index;
  final Uint8List value;
}

final class _ParityEquation extends _Equation {
  const _ParityEquation(this.coeffs, this.value);
  final List<int> coeffs;
  final Uint8List value;
}
