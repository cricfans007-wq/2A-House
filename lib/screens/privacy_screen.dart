import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.45,
    );
    return GlassScaffold(
      background: const HouseGlassBackground(),
      statusBarStyle: GlassStatusBarStyle.auto,
      extendBody: false,
      appBar: GlassAppBar(
        centerTitle: false,
        leading: GlassIconButton(
          icon: const Icon(Icons.arrow_back),
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Privacy policy'),
      ),
      body: Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              '2A House',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text('Last updated: 20 August 2026', style: muted),
            const SizedBox(height: 16),
            Text(
              'This policy is for the 2A House app, a shared cleaning roster for one household.',
              style: muted,
            ),
            _h(context, 'Who we are'),
            Text(
              '2A House is published by the developer named on the Google Play listing. It is meant for the people who live in the house, not the general public.',
              style: muted,
            ),
            _h(context, 'What we collect'),
            Text(
              'First names you type in the app, which room each person is in, and which person this phone belongs to (kept on that phone).\n\n'
              'Chore records: who is assigned, whether a job is done, who marked it done, whether someone told the house they cannot do a job, and makeup / 2× records.\n\n'
              'An anonymous ID from Google Firebase so this phone can sync. We do not ask for an email, phone number, or password.',
              style: muted,
            ),
            _h(context, 'What we do not collect'),
            Text(
              'We do not collect location, contacts, photos, or payment details. There are no ads, and we do not sell data.',
              style: muted,
            ),
            _h(context, 'How we use it'),
            Text(
              'To show the roster, keep the six phones in sync, send reminders and house pings on the device, and apply the missed-job makeup rule.',
              style: muted,
            ),
            _h(context, 'Where it is stored'),
            Text(
              'On the phone, and in Google Firebase (Cloud Firestore and anonymous Authentication) so the other phones in the house stay in sync. Google processes this as our cloud provider.',
              style: muted,
            ),
            _h(context, 'Who sees it'),
            Text(
              'Anyone who installs 2A House and reaches the same house board can see the names and chore records on that board.',
              style: muted,
            ),
            _h(context, 'Notifications'),
            Text(
              'Night-before reminders, morning reminders, and “someone finished / told the house” pings stay on the device. We do not use push-notification servers.',
              style: muted,
            ),
            _h(context, 'Keeping or deleting data'),
            Text(
              'You can change a name in House. Chore records stay until someone in the house updates them. To ask for house data to be removed from the cloud, use the developer contact email on the Google Play listing for 2A House.',
              style: muted,
            ),
            _h(context, 'Children'),
            Text('This app is not directed at children.', style: muted),
            _h(context, 'Changes'),
            Text(
              'If this policy changes, we will update the date at the top.',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _h(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
