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
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _validateName(String val) {
    setState(() {
      if (val.isEmpty) {
        _nameError = null;
        _nameValid = false;
      } else if (val.length < 2) {
        _nameError = 'Name must be at least 2 characters';
        _nameValid = false;
      } else {
        _nameError = null;
        _nameValid = true;
      }
    });
  }

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

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _validateName(name);
    _validateEmail(email);
    _validatePassword(password);

    if (!_nameValid || !_emailValid || !_passwordValid) {
      return;
    }



    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.signup(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['statusCode'] == 201) {
      _showAlertDialog(
        title: 'Thành công',
        message: 'Tài khoản của bạn đã được đăng ký thành công! Đang chuyển hướng đến trang Đăng nhập...',
        isSuccess: true,
      );
    } else {
      _showAlertDialog(
        title: 'Đăng ký thất bại',
        message: res['data']['message'] == 'EMAIL_ALREADY_EXISTS'
            ? 'Email này đã được đăng ký.'
            : res['data']['message'] ?? 'Không thể hoàn tất đăng ký.',
        isSuccess: false,
      );
    }
  }

  void _showAlertDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isSuccess) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
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

  Future<void> _handleSocialSignUp(String provider) async {
    setState(() {
      _isLoading = true;
    });

    String? token;
    String name = '';
    String email = '';
    String? photoUrl;

    try {
      if (provider.toLowerCase() == 'google') {
        await GoogleSignIn.instance.initialize(
          serverClientId:
      '999208182045-p093pkpunvjokr8b9o1m1p2j4k5ahq91.apps.googleusercontent.com',
        );
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
        final result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
        if (result.status == LoginStatus.success) {
          token = result.accessToken?.tokenString;

          final userData = await FacebookAuth.instance.getUserData();
          name = userData['name'] ?? 'Facebook User';
          email = userData['email'] ?? '';
          if (email.isEmpty) {
            email = 'fb_${userData['id']}@facebook.com';
          }
          photoUrl = userData['picture']?['data']?['url'];
        }
      }
    } catch (e) {
      debugPrint('Real social auth failed: $e');
      if (!mounted) return;
      _showErrorDialog('Không thể kết nối tài khoản $provider. Vui lòng thử lại.');
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
        _showErrorDialog('Đăng ký thất bại (Đã hủy liên kết tài khoản)');
        return;
      }

      _sendSocialTokenToBackend(provider, token);
    }
  }

  Future<void> _sendSocialTokenToBackend(String provider, String token) async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.socialLogin(provider, token, signUp: true);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res['statusCode'] == 200 || res['statusCode'] == 201) {
      if (res['data']['message'] == 'LOGIN_SUCCESSFUL') {
        final user = UserModel.fromJson(res['data']['user']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      } else {
        _showAlertDialog(
          title: 'Thành công',
          message: 'Tài khoản $provider của bạn đã được đăng ký thành công! Đang chuyển hướng đến trang Đăng nhập...',
          isSuccess: true,
        );
      }
    } else {
      _showErrorDialog(res['data']['message'] ?? 'Xác thực tài khoản mạng xã hội thất bại.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: Text(
          'Lỗi đăng ký',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          message,
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Sign up',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 45),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Name',
                  hintText: '',
                  errorText: _nameError,
                  isValid: _nameValid,
                  onChanged: _validateName,
                ),
                const SizedBox(height: 16),
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
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account?',
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
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Sign up',
                  isLoading: _isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 96),
                Center(
                  child: Text(
                    'Or sign up with social account',
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
                      onTap: () => _handleSocialSignUp('Google'),
                    ),
                    const SizedBox(width: 16),
                    SocialButton(
                      provider: 'facebook',
                      onTap: () => _handleSocialSignUp('Facebook'),
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
