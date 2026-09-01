import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  Future<String> _loadLicensesAndNotice() async {
    try {
      final noticeText = await rootBundle.loadString('NOTICE');
      return noticeText;
    } catch (e, stack) {
      Error.throwWithStackTrace(
        Exception('Failed to load NOTICE file: $e'),
        stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.legalInfo)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: _loadLicensesAndNotice(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return ErrorMessage(
                  message: AppLocalizations.of(context)!.noticeErrorDetail,
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(child: Text(snapshot.data!)),
              );
            },
          ),
        ),
      ),
    );
  }
}
