import 'package:flutter/material.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  static const routeName = '/faq';

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
    final theme = Theme.of(context);

    final List<Map<String, String>> qaPairs = [
      {
        'q': localizations.faqQ1,
        'a': localizations.faqA1,
      },
      {
        'q': localizations.faqQ2,
        'a': localizations.faqA2,
      },
      {
        'q': localizations.faqQ3,
        'a': localizations.faqA3,
      },
      {
        'q': localizations.faqQ4,
        'a': localizations.faqA4,
      },
      {
        'q': localizations.faqQ5,
        'a': localizations.faqA5,
      },
      {
        'q': localizations.faqQ6,
        'a': localizations.faqA6,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.faqAndContacts),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Contacts Section
          Card(
            color: lightGrayColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // ListTile(
                  //   title: Text(localizations.faqBot, style: const TextStyle(color: lightColor)),
                  //   leading: const Icon(Icons.smart_toy_outlined, color: primaryColor, size: 28),
                  //   onTap: () => _launchURL('https://t.me/hwlvpn_bot'), // Placeholder
                  // ),
                  //const Divider(color: darkColor, height: 1),
                  ListTile(
                    title: Text(localizations.faqSupport, style: const TextStyle(color: lightColor)),
                    leading: const Icon(Icons.support_agent, color: primaryColor, size: 28),
                    onTap: () => _launchURL('https://t.me/hinalabs'),
                  ),
                  const Divider(color: darkColor, height: 1),
                  ListTile(
                    title: Text(localizations.faqTelegramChannel, style: const TextStyle(color: lightColor)),
                    leading: const Icon(Icons.send_outlined, color: primaryColor, size: 28),
                    onTap: () => _launchURL(localizations.faqTelegramChannelLink),
                  ),
                  const Divider(color: darkColor, height: 1),
                  ListTile(
                    title: Text(localizations.faqWebsite, style: const TextStyle(color: lightColor)),
                    leading: const Icon(Icons.public, color: primaryColor, size: 28),
                    onTap: () => _launchURL(localizations.faqWebsiteLink),
                  ),
                  const Divider(color: darkColor, height: 1),
                  ListTile(
                    title: Text(localizations.faqSupportEmail, style: const TextStyle(color: lightColor)),
                    leading: const Icon(Icons.email_outlined, color: primaryColor, size: 28),
                    onTap: () => _launchURL('mailto:${localizations.faqSupportEmailAddress}'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // FAQ Section
          Text(
            localizations.faqTitle,
            style: theme.textTheme.titleLarge?.copyWith(color: lightColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...qaPairs.map((pair) {
            return Card(
              color: lightGrayColor.withOpacity(0.5),
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(pair['q']!, style: const TextStyle(color: lightColor, fontWeight: FontWeight.w600)),
                  iconColor: primaryColor,
                  collapsedIconColor: lightColor,
                  children: [
                    Container(
                      color: darkColor.withOpacity(0.3),
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        pair['a']!,
                        style: TextStyle(color: lightColor.withOpacity(0.8), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}