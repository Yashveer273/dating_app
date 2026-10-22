import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talk24loves/components/AnimatedCustomHeart.dart';
import 'package:talk24loves/components/app_colors.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.isDarkMode});

  final bool isDarkMode;

  static const String privacyPolicyUrl =
      'https://magical-rolypoly-69fd5c.netlify.app/';

  static const String supportEmail = 'businessbala95@gmail.com';

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(privacyPolicyUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Talk24 Support'},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFE5E7EB);

    final secondaryTextColor = isDarkMode
        ? const Color(0xFFA3A3A3)
        : const Color(0xFF666666);

    final linkColor = isDarkMode ? Colors.white : const Color(0xFF333333);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            color: borderColor.withOpacity(0.6),
            thickness: 0.8,
            height: 16,
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            children: [
              GestureDetector(
                onTap: _openPrivacyPolicy,
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openSupportEmail,
                child: Text(
                  'Child Safety & Support',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '© 2026 Talk24.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}
