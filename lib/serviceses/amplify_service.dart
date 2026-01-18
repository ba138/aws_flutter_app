import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_api/amplify_api.dart';

import '../amplifyconfiguration.dart';

class AmplifyService {
  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured) return;

    try {
      // 1️⃣ Add all Amplify plugins
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyStorageS3(),
        AmplifyAPI(),
      ]);

      // 2️⃣ Configure Amplify
      await Amplify.configure(amplifyconfig);

      _configured = true;
      safePrint('Amplify configured successfully');
    } on AmplifyAlreadyConfiguredException {
      safePrint('Amplify was already configured');
    } catch (e) {
      safePrint('Amplify error: $e');
    }
  }
}
