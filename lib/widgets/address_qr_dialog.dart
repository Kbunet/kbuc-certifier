import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A dialog for displaying QR codes for addresses with multiple modes
/// Similar to QRDialog but with options specific to addresses
class AddressQRDialog extends StatefulWidget {
  final String title;
  final String address;
  final String label;

  const AddressQRDialog({
    super.key,
    required this.title,
    required this.address,
    required this.label,
  });
  
  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String address,
    required String label,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddressQRDialog(
        title: title,
        address: address,
        label: label,
      ),
    );
  }

  @override
  State<AddressQRDialog> createState() => _AddressQRDialogState();
}

class _AddressQRDialogState extends State<AddressQRDialog> {
  // 0: plain hash, 1: support (send RPS), 2: verify
  int _qrMode = 0;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final localizations = AppLocalizations.of(context)!;
    
    // Prepare display data and title based on mode
    String displayData;
    String modeTitle;
    
    switch (_qrMode) {
      case 1: // Support
        displayData = 'UR:SEND-RPS/${widget.address}';
        modeTitle = localizations.supportAddress;
        break;
      case 2: // Verify
        displayData = 'UR:VERIFY-PROFILE/${widget.address}';
        modeTitle = localizations.verifyAddress;
        break;
      default: // Plain hash
        displayData = widget.address;
        modeTitle = localizations.addressHash;
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              localizations.addressQRTitle(widget.label),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Display mode subtitle when not in plain hash mode
            if (_qrMode > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  modeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // QR Code
            Container(
              width: isSmallScreen ? 200 : 260,
              height: isSmallScreen ? 200 : 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: displayData,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                size: isSmallScreen ? 180 : 240,
                padding: const EdgeInsets.all(8),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Data text (shortened with copy option)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayData.length > 20 ? '${displayData.substring(0, 20)}...' : displayData,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: colorScheme.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.copiedToClipboard)),
                    );
                  },
                  tooltip: localizations.copyToClipboard,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Mode toggle buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => setState(() => _qrMode = 0),
                  style: TextButton.styleFrom(
                    backgroundColor: _qrMode == 0 ? colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Text(localizations.hash),
                ),
                TextButton(
                  onPressed: () => setState(() => _qrMode = 1),
                  style: TextButton.styleFrom(
                    backgroundColor: _qrMode == 1 ? colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Text(localizations.support),
                ),
                TextButton(
                  onPressed: () => setState(() => _qrMode = 2),
                  style: TextButton.styleFrom(
                    backgroundColor: _qrMode == 2 ? colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Text(localizations.verify),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.copiedToClipboard)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(localizations.copy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(localizations.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
