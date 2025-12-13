import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// A dismissible discovery card that promotes the hands-free voice mode feature.
/// Shows on the home screen for users who haven't tried or dismissed it.
class HandsFreeDiscoveryCard extends StatefulWidget {
  final VoidCallback? onEnablePressed;
  final VoidCallback? onDismissed;

  const HandsFreeDiscoveryCard({
    super.key,
    this.onEnablePressed,
    this.onDismissed,
  });

  @override
  State<HandsFreeDiscoveryCard> createState() => _HandsFreeDiscoveryCardState();
}

class _HandsFreeDiscoveryCardState extends State<HandsFreeDiscoveryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.5),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and dismiss button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bluetooth_audio,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hands-Free Voice Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: _dismiss,
                        tooltip: 'Dismiss',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Add todos while driving using your Bluetooth headset button. '
                    'Just press the button, speak, and hear confirmation - no screen needed!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Features list
                  Row(
                    children: [
                      _FeatureChip(
                        icon: Icons.mic,
                        label: 'Voice',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _FeatureChip(
                        icon: Icons.volume_up,
                        label: 'Audio Feedback',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      _FeatureChip(
                        icon: Icons.directions_car,
                        label: 'Driving Safe',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onEnablePressed?.call();
                        _dismiss();
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Enable in Settings'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to manage discovery card visibility state
class HandsFreeDiscoveryManager {
  static const String _dismissedKey = 'handsFreeModeDiscoveryDismissed';
  static const String _enabledKey = 'handsFreeModeEnabled';

  final StorageService _storage;

  HandsFreeDiscoveryManager({StorageService? storage})
      : _storage = storage ?? StorageService();

  /// Check if the discovery card should be shown
  Future<bool> shouldShowDiscoveryCard() async {
    try {
      final settings = await _storage.loadSettings();

      // Don't show if already dismissed
      final dismissed = settings[_dismissedKey] as bool? ?? false;
      if (dismissed) return false;

      // Don't show if hands-free mode is already enabled
      final enabled = settings[_enabledKey] as bool? ?? false;
      if (enabled) return false;

      return true;
    } catch (e) {
      // If there's any error loading settings, don't show the card
      // This prevents crashes during backup restore or other edge cases
      return false;
    }
  }

  /// Mark the discovery card as dismissed
  Future<void> dismissDiscoveryCard() async {
    try {
      final settings = await _storage.loadSettings();
      settings[_dismissedKey] = true;
      await _storage.saveSettings(settings);
    } catch (e) {
      // Silently fail - not critical functionality
    }
  }
}
