import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/safety_plan.dart';
import '../theme/app_spacing.dart';

/// Screen displaying UK crisis resources and emergency contacts
///
/// Provides immediate access to crisis hotlines including:
/// - Samaritans (116 123)
/// - Shout Crisis Text Line (85258)
/// - NHS 111
/// - Emergency Services (999)
/// - And other mental health support lines
///
/// This screen should be easily accessible from anywhere in the app
/// via a persistent crisis banner or dedicated button.
class CrisisResourcesScreen extends StatelessWidget {
  const CrisisResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ukCrisisContacts = _getUKCrisisContacts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis Support'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: 100, // Extra padding for bottom nav (80px) + spacing (20px)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgent help banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: theme.colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'If you\'re in immediate danger',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Call 999 for emergency services or go to your nearest A&E.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _makePhoneCall('999'),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call 999 (Emergency)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Introduction text
            Text(
              'You don\'t have to face this alone',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'These services provide free, confidential support 24/7. '
              'Reaching out is a sign of strength, not weakness.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Crisis hotlines
            Text(
              '24/7 Crisis Support',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...ukCrisisContacts
                .where((contact) => contact.isEmergency)
                .map((contact) => _buildContactCard(context, contact)),

            const SizedBox(height: AppSpacing.xl),

            // Additional support
            Text(
              'Additional Support',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ...ukCrisisContacts
                .where((contact) => !contact.isEmergency)
                .map((contact) => _buildContactCard(context, contact)),

            const SizedBox(height: AppSpacing.xl),

            // Important information
            _buildInfoSection(
              context,
              icon: Icons.info_outline,
              title: 'What to expect when you call',
              content:
                  'Trained volunteers and professionals will listen without judgment. '
                  'You can talk about anything that\'s troubling you. '
                  'The call is confidential and you don\'t have to give your name.',
            ),

            const SizedBox(height: AppSpacing.md),

            _buildInfoSection(
              context,
              icon: Icons.schedule,
              title: 'Best times to call',
              content:
                  'Most services are available 24/7, but wait times may be longer during evenings. '
                  'If the line is busy, please try again or try a different service.',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Safety plan CTA
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a Safety Plan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'A safety plan helps you prepare for difficult moments. '
                    'It includes coping strategies, people to contact, and reasons to keep going.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/safety-plan');
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Create Safety Plan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, CrisisContact contact) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _makePhoneCall(contact.phone),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: contact.isEmergency
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone,
                  color: contact.isEmergency
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relationship,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phone,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.phone_forwarded,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get UK crisis contacts
  List<CrisisContact> _getUKCrisisContacts() {
    return [
      CrisisContact(
        name: 'Samaritans',
        phone: '116 123',
        relationship: 'Free to call 24/7, 365 days a year',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Shout Crisis Text Line',
        phone: '85258',
        relationship: 'Text SHOUT to this number (free, 24/7)',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'NHS 111',
        phone: '111',
        relationship: 'Mental health crisis support (24/7)',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Papyrus (Under 35s)',
        phone: '0800 068 4141',
        relationship: 'Suicide prevention, Mon-Fri 10am-10pm, weekends 2pm-10pm',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'CALM (Men)',
        phone: '0800 58 58 58',
        relationship: 'Campaign Against Living Miserably, daily 5pm-midnight',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Mind Infoline',
        phone: '0300 123 3393',
        relationship: 'Mental health information, Mon-Fri 9am-6pm',
        isEmergency: false,
      ),
      CrisisContact(
        name: 'The Mix (Under 25s)',
        phone: '0808 808 4994',
        relationship: 'Support for young people, daily 3pm-midnight',
        isEmergency: false,
      ),
      CrisisContact(
        name: 'Refuge (Domestic Abuse)',
        phone: '0808 2000 247',
        relationship: 'National Domestic Abuse Helpline (24/7)',
        isEmergency: false,
      ),
    ];
  }

  /// Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Remove spaces for the tel: URI
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
