import '../../protocols/transfer_method.dart';
import '../domain/transfer_record.dart';

/// Mock history repository with seeded transfer records for UI development.
class MockHistoryRepository {
  Future<List<TransferRecord>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _seededRecords;
  }

  static final List<TransferRecord> _seededRecords = [
    TransferRecord(
      id: '1',
      fileName: 'project_report.pdf',
      method: TransferMethod.qr,
      sizeBytes: 2457600,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '2',
      fileName: 'vacation_photo.jpg',
      method: TransferMethod.colorMatrix,
      sizeBytes: 4194304,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      direction: TransferDirection.received,
    ),
    TransferRecord(
      id: '3',
      fileName: 'presentation.pptx',
      method: TransferMethod.qr,
      sizeBytes: 8388608,
      status: TransferStatus.failed,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '4',
      fileName: 'notes.txt',
      method: TransferMethod.qr,
      sizeBytes: 4096,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      direction: TransferDirection.received,
    ),
    TransferRecord(
      id: '5',
      fileName: 'demo_video.mp4',
      method: TransferMethod.opticalStream,
      sizeBytes: 52428800,
      status: TransferStatus.cancelled,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '6',
      fileName: 'config.json',
      method: TransferMethod.colorMatrix,
      sizeBytes: 2048,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      direction: TransferDirection.received,
    ),
    TransferRecord(
      id: '7',
      fileName: 'archive.zip',
      method: TransferMethod.qr,
      sizeBytes: 15728640,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '8',
      fileName: 'screenshot.png',
      method: TransferMethod.colorMatrix,
      sizeBytes: 1048576,
      status: TransferStatus.failed,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      direction: TransferDirection.received,
    ),
    TransferRecord(
      id: '9',
      fileName: 'music_track.mp3',
      method: TransferMethod.opticalStream,
      sizeBytes: 6291456,
      status: TransferStatus.inProgress,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '10',
      fileName: 'readme.md',
      method: TransferMethod.qr,
      sizeBytes: 8192,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      direction: TransferDirection.received,
    ),
    TransferRecord(
      id: '11',
      fileName: 'dataset.csv',
      method: TransferMethod.colorMatrix,
      sizeBytes: 3145728,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 6)),
      direction: TransferDirection.sent,
    ),
    TransferRecord(
      id: '12',
      fileName: 'backup.db',
      method: TransferMethod.opticalStream,
      sizeBytes: 20971520,
      status: TransferStatus.success,
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      direction: TransferDirection.received,
    ),
  ];
}
