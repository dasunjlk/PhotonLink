import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import 'adaptation_diagnostics.dart';

/// Exports adaptive + frame diagnostics to a JSON file.
class DiagnosticsExporter {
  Future<String> exportToFile({
    required AdaptationDiagnostics adaptation,
    FrameDiagnostics? frameDiagnostics,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'photonlink_diagnostics_${DateTime.now().millisecondsSinceEpoch}.json';
    final path = '${dir.path}/$name';

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'adaptation': adaptation.toJson(),
      if (frameDiagnostics != null)
        'frameDiagnostics': frameDiagnostics.toJson(),
    };

    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return path;
  }
}
