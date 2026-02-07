import 'package:flutter/material.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/utils/colors.dart';

class PersonalKeyScreen extends StatefulWidget {
  const PersonalKeyScreen({super.key});
  static const routeName = '/personal-key';

  @override
  State<PersonalKeyScreen> createState() => _PersonalKeyScreenState();
}

class _PersonalKeyScreenState extends State<PersonalKeyScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonalKey();
    _keyController.addListener(() {
      _prefsService.savePersonalKey(_keyController.text);
    });
  }

  Future<void> _loadPersonalKey() async {
    final key = await _prefsService.getPersonalKey();
    if (key != null) {
      _keyController.text = key;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.personalKeys),
        actions: [
          Tooltip(
            message: localizations.personalKeysClear,
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                _keyController.clear();
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(color: lightColor.withOpacity(0.9), fontSize: 14),
              children: <TextSpan>[
                TextSpan(text: localizations.personalKeysWarningTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                TextSpan(text: localizations.personalKeysWarningBody),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            style: const TextStyle(color: lightColor),
            decoration: InputDecoration(
              hintText: localizations.personalKeysEnterLink,
              hintStyle: TextStyle(color: lightColor.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: lightGrayColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.personalKeysExplanation1,
                style: TextStyle(color: lightColor.withOpacity(0.9), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.personalKeysExplanation2,
                style: TextStyle(color: lightColor.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.personalKeysExplanationVless,
                      style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.personalKeysExplanationSsh,
                      style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.personalKeysExplanationHysteria2,
                      style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.personalKeysExplanation3,
                style: TextStyle(color: lightColor.withOpacity(0.9), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
