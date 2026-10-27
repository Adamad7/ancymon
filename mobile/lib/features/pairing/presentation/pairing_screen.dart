import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/models/connection_config.dart';
import '../../../core/providers/connection_provider.dart';

/// Screen for onboarding and pairing the mobile app with the AncyMon server.
/// Uses [MobileScanner] to scan the terminal QR code or allows manual JSON paste.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleQrPayload(String rawPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final config = ConnectionConfig.fromJsonString(rawPayload);
      await ref.read(connectionConfigProvider.notifier).pair(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully paired with ${config.ip}:${config.port}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pairing failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualInputDialog() {
    _manualInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Pairing JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the minified pairing payload JSON from the server terminal output:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('manual_json_input'),
              controller: _manualInputController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"ip":"...","port":443,"token":"...","ca":"..."}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('submit_manual_json_button'),
            onPressed: () {
              final text = _manualInputController.text.trim();
              Navigator.of(ctx).pop();
              if (text.isNotEmpty) {
                _handleQrPayload(text);
              }
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Workstation Fleet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _handleQrPayload(rawValue);
                  break;
                }
              }
            },
          ),
          // Viewfinder overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Point camera at the terminal QR code displayed by AncyMon Server',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('enter_manually_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isProcessing ? null : _showManualInputDialog,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Enter Payload Manually'),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
