import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialButton extends StatelessWidget {
  final String provider; // "google" or "facebook"
  final VoidCallback onTap;

  const SocialButton({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider.toLowerCase() == 'google';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            isGoogle ? 'assets/icons/google.svg' : 'assets/icons/facebook.svg',
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}
