import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) return 'http://localhost:5053/api';
  if (Platform.isAndroid) return 'http://10.0.2.2:5053/api'; // emulator
  return 'http://192.168.1.8:5053/api'; // thiết bị thật
}
