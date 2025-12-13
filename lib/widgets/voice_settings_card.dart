import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/voice_activation_service.dart';
import '../services/storage_service.dart';

/// Settings card for voice activation options
class VoiceSettingsCard extends StatefulWidget {
  const VoiceSettingsCard({super.key});

  @override
  State<VoiceSettingsCard> createState() => _VoiceSettingsCardState();
}

class _VoiceSettingsCardState extends State<VoiceSettingsCard> {
  final _voiceService = VoiceActivationService.instance;
  final _storage = StorageService();

  bool _isAvailable = false;
  bool _showVoiceButton = true;
  bool _shakeToActivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (kIsWeb) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
      });
      return;
    }

    final available = await _voiceService.isAvailable();
    final settings = await _storage.loadSettings();

    if (mounted) {
      setState(() {
        _isAvailable = available;
        _showVoiceButton = settings['showVoiceButton'] as bool? ?? true;
        _shakeToActivate = settings['shakeToActivateVoice'] as bool? ?? false;
        _isLoading = false;
      });

      // Enable shake if it was previously enabled
      if (_shakeToActivate && available) {
        _voiceService.enableShakeActivation();
      }
    }
  }

  Future<void> _toggleVoiceButton(bool value) async {
    setState(() => _showVoiceButton = value);

    final settings = await _storage.loadSettings();
    settings['showVoiceButton'] = value;
    await _storage.saveSettings(settings);
  }

  Future<void> _toggleShakeActivation(bool value) async {
    setState(() => _shakeToActivate = value);

    if (value) {
      await _voiceService.enableShakeActivation();
    } else {
      await _voiceService.disableShakeActivation();
    }

    final settings = await _storage.loadSettings();
    settings['shakeToActivateVoice'] = value;
    await _storage.saveSettings(settings);
  }

  Future<void> _testVoiceCapture() async {
    final hasPermission = await _voiceService.ensurePermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice capture'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show listening dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.red),
              SizedBox(width: 12),
              Text('Listening...'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Say something like:\n"Buy groceries tomorrow"'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _voiceService.cancel();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    final result = await _voiceService.activate(
      promptHint: 'Say what you need to do',
    );

    if (mounted) {
      Navigator.pop(context); // Close listening dialog

      if (result != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Voice Captured!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${result['title']}'),
                if (result['dueDate'] != null)
                  Text('Due: ${result['dueDate']}'),
                if (result['priority'] != null)
                  Text('Priority: ${result['priority']}'),
                const SizedBox(height: 8),
                Text(
                  'Original: "${result['originalTranscript']}"',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speech detected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Voice capture is not available on web',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isAvailable) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.orange),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Voice capture is not available on this device',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Capture',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Create todos using your voice',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _testVoiceCapture,
                  icon: const Icon(Icons.mic, size: 18),
                  label: const Text('Test'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Show floating button toggle
          SwitchListTile(
            title: const Text('Show Voice Button'),
            subtitle: const Text('Display floating mic button on home screen'),
            value: _showVoiceButton,
            onChanged: _toggleVoiceButton,
            secondary: const Icon(Icons.touch_app),
          ),

          // Shake to activate toggle
          SwitchListTile(
            title: const Text('Shake to Activate'),
            subtitle: const Text('Shake your phone to start voice capture'),
            value: _shakeToActivate,
            onChanged: _toggleShakeActivation,
            secondary: const Icon(Icons.vibration),
          ),

          // Tips section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Commands',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try saying things like:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '  \u2022 "Buy groceries tomorrow"\n'
                    '  \u2022 "Urgent: call the doctor"\n'
                    '  \u2022 "Finish report by Friday"\n'
                    '  \u2022 "Low priority: clean garage"',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
