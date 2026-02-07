import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/home_screen.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});
  static const routeName = '/agreement';

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _privacyPolicyAccepted = false;
  bool _termsOfUseAccepted = false;
  final _prefsService = PreferencesService();

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bool agreementsAccepted = _privacyPolicyAccepted && _termsOfUseAccepted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                localizations.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: lightColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.updateTermsMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: lightColor.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _privacyPolicyAccepted,
                      onChanged: (value) {
                        setState(() {
                          _privacyPolicyAccepted = value!;
                        });
                      },
                      checkColor: darkColor,
                      activeColor: primaryColor,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14, fontFamily: 'NotoSansMono'),
                          children: [
                            TextSpan(text: '${localizations.iAccept} '),
                            TextSpan(
                              text: localizations.privacyPolicy,
                              style: const TextStyle(
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchURL(localizations.privacyPolicyLink);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _termsOfUseAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsOfUseAccepted = value!;
                        });
                      },
                      checkColor: darkColor,
                      activeColor: primaryColor,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14, fontFamily: 'NotoSansMono'),
                          children: [
                            TextSpan(text: '${localizations.iAccept} '),
                            TextSpan(
                              text: localizations.termsOfUse,
                              style: const TextStyle(
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchURL(localizations.termsOfUseLink);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: agreementsAccepted
                    ? () async {
                        await _prefsService.savePrivacyPolicyAccepted(true);
                        await _prefsService.saveTermsOfUseAccepted(true);
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (_) => false,
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: lightGrayColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  localizations.continueButton,
                  style: const TextStyle(fontSize: 18, color: lightColor),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
