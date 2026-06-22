import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../logger/app_logger.dart';

/// Decodes the first QR payload from a JPEG/PNG camera capture.
String? decodeQrFromImageBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    AppLogger.warning('[QR Decoder] Failed to decode camera image');
    return null;
  }

  // Use BGRA channel order so that on little-endian (Windows x86/x64) the
  // bytes [B, G, R, A] per pixel are interpreted as the int32 0xAARRGGBB
  // expected by ZXing's RGBLuminanceSource.
  final source = RGBLuminanceSource(
    image.width,
    image.height,
    image
        .convert(numChannels: 4)
        .getBytes(order: img.ChannelOrder.bgra)
        .buffer
        .asInt32List(),
  );
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  final reader = QRCodeReader();

  try {
    final result = reader.decode(bitmap).text;
    AppLogger.info('[QR Decoder] Decode succeeded (${result.length} chars)');
    return result;
  } catch (e) {
    AppLogger.warning('[QR Decoder] Decode failed: $e');
    return null;
  }
}
