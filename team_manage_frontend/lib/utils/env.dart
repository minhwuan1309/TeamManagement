import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) return 'https://api.crawlflow.xyz/api';
  if (Platform.isAndroid) return 'http://10.0.2.2:5053/api'; // emulator
  return 'http://192.168.1.8:5053/api'; // thiết bị thật
}

String metabasePublicUrl = 'http://192.168.1.28:3000/public/dashboard/5ada300c-3535-421c-8a59-6f62f31a5ddc';