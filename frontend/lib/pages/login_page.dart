import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/social_button.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../widgets/confirm_account_dialog.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  bool _emailValid = false;
  bool _passwordValid = false;

  bool _isLoading = false;

  void _validateEmail(String val) {
    setState(() {
      if (val.isEmpty) {
        _emailError = null;
        _emailValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
        _emailError = 'Not a valid email address. Should be your@email.com';
        _emailValid = false;
      } else {
        _emailError = null;
        _emailValid = true;
      }
    });
  }

  void _validatePassword(String val) {
    setState(() {
      if (val.isEmpty) {
        _passwordError = null;
        _passwordValid = false;
      } else if (val.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        _passwordValid = false;
      } else {
        _passwordError = null;
        _passwordValid = true;
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _validateEmail(email);
    _validatePassword(password);

    if (!_emailValid || !_passwordValid) {
      return;
    }

    

    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['statusCode'] == 200) {
      final user = UserModel.fromJson(res['data']['user']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: user)),
        (route) => false,
      );
    } else if (res['statusCode'] == 404 && res['data']['message'] == 'USER_NOT_FOUND') {
      _showRedirectSignUpDialog();
    } else {
      _showErrorDialog(res['data']['message'] ?? 'Invalid username or password');
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
    });

    String? token;
    String name = '';
    String email = '';
    String? photoUrl;

    try {
      if (provider.toLowerCase() == 'google') {
        // google_sign_in v7+ uses singleton and requires initialize() once
        await GoogleSignIn.instance.initialize(
          serverClientId:
      '999208182045-p093pkpunvjokr8b9o1m1p2j4k5ahq91.apps.googleusercontent.com',);
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        token = googleAuth.idToken;

        name = 'Google User';
        try {
          name = googleUser.displayName ?? 'Google User';
        } catch (_) {}

        email = 'google_user@gmail.com';
        try {
          email = googleUser.email;
        } catch (_) {}

        try {
          photoUrl = googleUser.photoUrl;
        } catch (_) {}
      } else {
        final result = await FacebookAuth.instance.login(
  permissions: ['email', 'public_profile'],
);

if (result.status == LoginStatus.success) {
  token = result.accessToken?.tokenString;

  final userData = await FacebookAuth.instance.getUserData(
    fields: "name,email,picture.width(200)",
  );

  name = userData['name'] ?? 'Facebook User';
  email = userData['email'] ?? '';

  if (email.isEmpty) {
    email = 'yenngoc123@gmail.com';
  }

  photoUrl = userData['picture']?['data']?['url'];
}
      }
    } catch (e) {
        debugPrint('GOOGLE ERROR = $e');

        if (!mounted) return;

        _showErrorDialog(e.toString());
      }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (token != null) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ConfirmAccountDialog(
          provider: provider,
          name: name,
          email: email,
          photoUrl: photoUrl,
        ),
      );

      if (confirm != true) {
        _showErrorDialog('Đăng nhập thất bại (Đã hủy liên kết tài khoản)');
        return;
      }

      _sendSocialTokenToBackend(provider, token);
    }
  }

  Future<void> _sendSocialTokenToBackend(String provider, String token) async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.socialLogin(provider, token, signUp: false);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['statusCode'] == 200) {
      final user = UserModel.fromJson(res['data']['user']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: user)),
        (route) => false,
      );
    } else if (res['statusCode'] == 404 && res['data']['message'] == 'USER_NOT_FOUND') {
      _showRedirectSignUpDialog();
    } else {
      _showErrorDialog(res['data']['message'] ?? 'Social login failed');
    }
  }

  void _showRedirectSignUpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: Text(
          'Account Not Found',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Tài khoản này chưa tồn tại trong hệ thống. Bạn có muốn chuyển sang trang Đăng ký ngay bây giờ?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'HỦY',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpPage(),
                ),
              );
            },
            child: Text(
              'ĐĂNG KÝ',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: Text(
          'Login Error',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          message == 'USER_NOT_FOUND' 
              ? 'Tài khoản không tồn tại.' 
              : message == 'INVALID_CREDENTIALS' 
                  ? 'Mật khẩu không chính xác.' 
                  : message,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: AppColors.background,

  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios,
        color: AppColors.textPrimary,
      ),
      onPressed: () {
        SystemNavigator.pop();
      },
    ),
  ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Login',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 63),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: '',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  isValid: _emailValid,
                  onChanged: _validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: '',
                  isPassword: true,
                  errorText: _passwordError,
                  isValid: _passwordValid,
                  onChanged: _validatePassword,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Forgot your password?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_right_alt,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Login',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),

Center(
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SignUpPage(),
        ),
      );
    },
    child: RichText(
      text: TextSpan(
        text: "Don't have an account? ",
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        children: [
          TextSpan(
            text: 'Sign up',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  ),
),
                const SizedBox(height: 110),
                Center(
                  child: Text(
                    'Or login with social account',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(
                      provider: 'google',
                      onTap: () => _handleSocialLogin('Google'),
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      provider: 'facebook',
                      onTap: () => _handleSocialLogin('Facebook'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
