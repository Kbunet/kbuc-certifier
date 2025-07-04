import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class QRDialog extends StatefulWidget {
  final String title;
  final String data;
  final VoidCallback? onVerify;

  const QRDialog({
    super.key,
    required this.title,
    required this.data,
    this.onVerify,
  });
  
  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String data,
    VoidCallback? onVerify,
  }) {
    return showDialog(
      context: context,
      builder: (context) => QRDialog(
        title: title,
        data: data,
        onVerify: onVerify,
      ),
    );
  }

  @override
  State<QRDialog> createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  // 0: plain hash, 1: register, 2: verify
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
      case 1: // Register
        displayData = 'UR:SEND-RPS/${widget.data}';
        modeTitle = localizations.registerCertificate;
        break;
      case 2: // Verify
        displayData = 'UR:VERIFY-PROFILE/${widget.data}';
        modeTitle = localizations.verifyCertificate;
        break;
      default: // Plain hash
        displayData = widget.data;
        modeTitle = localizations.certificateHash;
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
              widget.title,
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
                  child: Text(localizations.register),
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
                if (widget.onVerify != null)
                  ElevatedButton.icon(
                    onPressed: widget.onVerify,
                    icon: const Icon(Icons.verified_user, size: 18),
                    label: Text(localizations.verify),
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
