import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/services/server_service.dart';
import 'package:hwl_vpn/utils/colors.dart';
import 'package:provider/provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  static const routeName = '/logs';

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _scrollController = ScrollController();
  late final ServerService _serverService;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _serverService = context.read<ServerService>();
    _serverService.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _serverService.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.logsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ServerService>().clearLogs();
            },
            tooltip: localizations.clearLogsTooltip,
          ),
        ],
      ),
      body: Container(
        color: darkColor,
        child: Consumer<ServerService>(
          builder: (context, serverService, child) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(
                serverService.logs.isEmpty
                    ? localizations.noLogsToShow
                    : serverService.logs,
                style: const TextStyle(
                  color: lightColor,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}