import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/account_screen.dart';
import 'package:hwl_vpn/screens/home_screen.dart';
import 'package:hwl_vpn/screens/settings_screen.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/utils/colors.dart';
import 'package:hwl_vpn/api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _privacyPolicyAccepted = false;
  bool _termsOfUseAccepted = false;

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.settings),
            tooltip: localizations.settings,
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                localizations.welcomeMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: lightColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.onboardingDescription,
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
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14),
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
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14),
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
                        final prefs = PreferencesService();
                        await prefs.savePrivacyPolicyAccepted(true);
                        await prefs.saveTermsOfUseAccepted(true);
                        
                        if (await prefs.getOfflineMode()) {
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                          }
                          return;
                        }

                        if (mounted) {
                          Navigator.pushNamed(context, AccountScreen.routeName);
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
                  localizations.authorize,
                  style: const TextStyle(fontSize: 18, color: lightColor),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: agreementsAccepted
                    ? () async {
                        final prefs = PreferencesService();
                        await prefs.savePrivacyPolicyAccepted(true);
                        await prefs.saveTermsOfUseAccepted(true);

                        if (await prefs.getOfflineMode()) {
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                          }
                          return;
                        }

                        await prefs.saveIsGuest(true);
                        await prefs.saveUseFreeServers(true);

                        final apiService = ApiService();
                        final result = await apiService.registerGuestInstance();

                        if (result['success'] && mounted) {
                          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                        } else if (mounted) {
                          // Handle error, e.g., show a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not register as guest: ${result['message']}')),
                          );
                        }
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: agreementsAccepted ? primaryColor : lightGrayColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  localizations.continueAsGuest,
                  style: TextStyle(fontSize: 18, color: agreementsAccepted ? primaryColor : lightGrayColor),
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