import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Returns the API base URL.
  ///
  /// Priority order:
  /// 1. `--dart-define=BASE_URL=...`
  /// 2. Web: `localhost`
  /// 3. Android emulator: `10.0.2.2`
  /// 4. Other platforms: `localhost`
  static String get baseUrl {
    // const fromDefine = String.fromEnvironment('BASE_URL', defaultValue: '');
    // if (fromDefine.isNotEmpty) return fromDefine;

    // if (kIsWeb) return 'http://localhost:3000';

    // switch (defaultTargetPlatform) {
    //   case TargetPlatform.android:
    //     return 'http://10.0.2.2:3000';
    //   case TargetPlatform.iOS:
    //   case TargetPlatform.macOS:
    //   case TargetPlatform.linux:
    //   case TargetPlatform.windows:
    //   default:
    //     return 'http://localhost:3000';
    // }
    return 'https://campus-club-manager.onrender.com';
  }
}
