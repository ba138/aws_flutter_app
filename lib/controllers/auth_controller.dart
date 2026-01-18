import 'package:aws_flutter_app/Screens/home_screen.dart';
import 'package:aws_flutter_app/Screens/login_screen.dart';
import 'package:aws_flutter_app/Screens/otp_verfication.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthController extends GetxController {
  /// UI state
  var isLoading = false.obs;
  var isLoggedIn = false.obs;

  /// Store email temporarily for verification & reset
  String _emailForVerification = '';

  /// =========================
  /// CHECK CURRENT USER
  /// =========================
  Future<void> checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      isLoggedIn.value = session.isSignedIn;

      if (session.isSignedIn) {
        Get.offAll(() => const HomeScreen());
        // Get.offAll(() => const LoginScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } catch (_) {
      Get.offAll(() => const LoginScreen());
    }
  }

  /// =========================
  /// SIGN UP (REGISTER)
  /// =========================
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;

      final result = await Amplify.Auth.signUp(
        username: email.trim(),
        password: password.trim(),
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email.trim(),
            AuthUserAttributeKey.name: name.trim(),
          },
        ),
      );

      _emailForVerification = email.trim();

      if (!result.isSignUpComplete) {
        Get.to(() => const VerifyEmailScreen());
      }
    } on AuthException catch (e) {
      Get.snackbar('Sign Up Failed', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================
  /// CONFIRM SIGN UP (OTP)
  /// =========================
  Future<void> confirmSignUp(String code) async {
    try {
      isLoading.value = true;

      final result = await Amplify.Auth.confirmSignUp(
        username: _emailForVerification,
        confirmationCode: code.trim(),
      );

      if (result.isSignUpComplete) {
        Get.snackbar('Success', 'Account verified successfully');
        Get.to(() => LoginScreen());
      }
    } on AuthException catch (e) {
      Get.snackbar('Verification Failed', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================
  /// SIGN IN (LOGIN)
  /// =========================
  Future<void> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;

      final result = await Amplify.Auth.signIn(
        username: email.trim(),
        password: password.trim(),
      );

      if (result.isSignedIn) {
        isLoggedIn.value = true;
        Get.offAll(() => const HomeScreen());
      }
    } on AuthException catch (e) {
      Get.snackbar('Login Failed', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================
  /// FORGOT PASSWORD
  /// =========================
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;

      await Amplify.Auth.resetPassword(username: email.trim());

      _emailForVerification = email.trim();

      Get.snackbar('Code Sent', 'Please check your email for reset code');

      Get.toNamed('/reset-password');
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================
  /// CONFIRM NEW PASSWORD
  /// =========================
  Future<void> confirmResetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;

      await Amplify.Auth.confirmResetPassword(
        username: _emailForVerification,
        newPassword: newPassword.trim(),
        confirmationCode: code.trim(),
      );

      Get.snackbar('Success', 'Password reset successfully');
      Get.offAllNamed('/login');
    } on AuthException catch (e) {
      Get.snackbar('Reset Failed', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  /// =========================
  /// SIGN OUT
  /// =========================
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      isLoggedIn.value = false;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout');
    }
  }
}
