import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _emailValid = false;
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

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    _validateEmail(email);

    if (_emailError != null || email.isEmpty) {
      if (email.isEmpty) {
        setState(() {
          _emailError = 'Email address cannot be empty';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.forgotPassword(email);

    setState(() {
      _isLoading = false;
    });

    if (res['statusCode'] == 200) {
      _showAlertDialog(
        title: 'Success',
        message: 'A password reset link has been sent to $email.',
        isSuccess: true,
      );
    } else {
      _showAlertDialog(
        title: 'Error',
        message: res['data']['message'] ?? 'Something went wrong',
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
                Navigator.pop(context); // Go back to login
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
                const SizedBox(height: 12),
                Text(
                  'Forgot password',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Please, enter your email address. You will receive a link to create a new password via email.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  isValid: _emailValid,
                  onChanged: _validateEmail,
                ),
                const SizedBox(height: 55),
                CustomButton(
                  text: 'Send',
                  isLoading: _isLoading,
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
