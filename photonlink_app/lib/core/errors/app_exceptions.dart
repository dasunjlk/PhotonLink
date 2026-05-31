/// Base exception type for PhotonLink errors.
sealed class PhotonLinkException implements Exception {
  const PhotonLinkException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'PhotonLinkException: $message';
}

/// Thrown when a required permission is denied.
final class PermissionDeniedException extends PhotonLinkException {
  const PermissionDeniedException(super.message, {super.cause});
}

/// Thrown when camera hardware is unavailable.
final class CameraUnavailableException extends PhotonLinkException {
  const CameraUnavailableException(super.message, {super.cause});
}

/// Thrown when a protocol operation is not yet implemented.
final class ProtocolNotImplementedException extends PhotonLinkException {
  const ProtocolNotImplementedException(super.message, {super.cause});
}

/// Thrown when file selection fails.
final class FilePickerException extends PhotonLinkException {
  const FilePickerException(super.message, {super.cause});
}
