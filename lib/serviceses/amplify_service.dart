import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:aws_flutter_app/amplifyconfiguration.dart';

class AmplifyService {
  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured) return;

    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);
      _configured = true;
    } catch (e) {
      safePrint('Amplify error: $e');
    }
  }
}
