import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../home/home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  int _step = 1; // 1: enter pin, 2: confirm pin
  bool _saving = false;
  String? _error;
  final _auth = AuthService();

  void _handleKey(String digit) {
    if (_saving) return;
    setState(() {
      _error = null;
      if (_step == 1) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            _step = 2;
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
        }
      }
    });
  }

  void _handleBackspace() {
    if (_saving) return;
    setState(() {
      _error = null;
      if (_step == 2 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_step == 2 && _confirmPin.isEmpty) {
        _step = 1;
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_step == 1 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_pin.length != 4 || _confirmPin.length != 4) return;
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Please re-enter.';
        _confirmPin = '';
        _step = 2;
      });
      return;
    }

    setState(() => _saving = true);
    await _auth.setPin(_pin);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _pin.length == 4 && _confirmPin.length == 4 && _pin == _confirmPin;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Top Offline Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'LOCAL SQLITE V3.42',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cloud_off, size: 14, color: AppTheme.onSurfaceVariant),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '100% Offline Mode',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Icon & Title Header
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 34),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock, size: 13, color: AppTheme.onSecondaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Apartment Management',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fully offline community manager powered by local encrypted SQLite',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.shield_outlined, size: 14, color: AppTheme.onSecondaryContainer),
                            SizedBox(width: 4),
                            Text(
                              'Set up your PIN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSecondaryContainer,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Master PIN Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Create Master PIN',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Set a 4-digit code to seal and encrypt local resident databases.',
                                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.key, size: 18, color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Step 1: Set PIN Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _step == 1 ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLow.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _step == 1 ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '1. SET 4-DIGIT PIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  _pin.length == 4 ? 'Saved' : '${_pin.length}/4 entered',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (i) {
                                final filled = i < _pin.length;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: filled ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Step 2: Confirm PIN Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _step == 2 ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLow.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _step == 2 ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '2. CONFIRM PIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _step == 2 ? AppTheme.primary : AppTheme.onSurfaceVariant,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  _confirmPin.length == 4
                                      ? (_confirmPin == _pin ? 'Matching ✓' : 'Mismatch! Retry')
                                      : '${_confirmPin.length}/4 entered',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _confirmPin.length == 4 && _confirmPin != _pin
                                        ? AppTheme.defaulterRed
                                        : AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (i) {
                                final filled = i < _confirmPin.length;
                                final mismatch = _confirmPin.length == 4 && _confirmPin != _pin;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? (mismatch ? AppTheme.defaulterRed : AppTheme.primary)
                                        : AppTheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.defaulterRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Keypad 3x4 Grid
                      _buildKeypad(),
                      const SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: canSubmit ? AppTheme.primaryContainer : AppTheme.surfaceContainerHighest,
                            foregroundColor: canSubmit ? Colors.white : AppTheme.onSurfaceVariant,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: canSubmit && !_saving ? _submit : null,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.verified_user, size: 18),
                          label: Text(
                            _saving ? 'ENCRYPTING DATABASE...' : 'SAVE MASTER PIN & ENTER',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Offline Notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_person_outlined, size: 16, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All data stays 100% offline on this device. Zero cloud sync required.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['backspace', '0', 'bio'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildKeyBtn(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyBtn(String key) {
    if (key == 'backspace') {
      return Material(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleBackspace,
          child: const SizedBox(
            height: 46,
            child: Center(
              child: Icon(Icons.backspace_outlined, size: 20, color: AppTheme.defaulterRed),
            ),
          ),
        ),
      );
    }

    if (key == 'bio') {
      return Material(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Device Biometrics will link to this Master PIN upon first unlock.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const SizedBox(
            height: 46,
            child: Center(
              child: Icon(Icons.fingerprint, size: 22, color: AppTheme.onSecondaryContainer),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleKey(key),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
