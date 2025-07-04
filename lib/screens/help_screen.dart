import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.helpAndInformation ?? 'Help & Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            title: AppLocalizations.of(context)?.aboutApp ?? 'About W3 Certificate Manager',
            content: AppLocalizations.of(context)?.aboutAppContent ?? 'W3 Certificate Manager is an application designed to create, manage, and verify academic certificates using the W3CertificateStandard based on CertHash v1.1 specification.',
            icon: Icons.info_outline,
          ),
          
          _buildSection(
            title: AppLocalizations.of(context)?.certificateTypes ?? 'Certificate Types',
            content: AppLocalizations.of(context)?.certificateTypesContent ?? 'The application supports various certificate types including: degree, attendance, appreciation, participation, completion, and honor certificates.',
            icon: Icons.category,
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.creatingCertificates ?? 'Creating Certificates',
            icon: Icons.add_circle_outline,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.singleCertificate ?? 'Single Certificate',
                content: AppLocalizations.of(context)?.singleCertificateContent ?? 'Tap the + button in the bottom right corner to create a new certificate. Fill in all required fields (marked with *) and any optional fields.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.batchImport ?? 'Batch Import',
                content: AppLocalizations.of(context)?.batchImportContent ?? 'Tap the chart icon to import multiple certificates at once using a CSV file. The CSV must include all required fields (type, recipient, issuer, description, date).',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.requiredFields ?? 'Required Fields',
                content: AppLocalizations.of(context)?.requiredFieldsContent ?? '• Type: The certificate type (degree, attendance, etc.)\n• Recipient: Person receiving the certificate\n• Issuer: Organization issuing the certificate\n• Description: Brief description of achievement\n• Date: Issue date in YYYY-MM-DD format',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.optionalFields ?? 'Optional Fields',
                content: AppLocalizations.of(context)?.optionalFieldsContent ?? '• Duration: Length of course/program\n• Event: Associated event name\n• Location: Where certificate was issued\n• Certificate ID: Unique identifier\n• Tags: Keywords for filtering (comma-separated)',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.managingCertificates ?? 'Managing Certificates',
            icon: Icons.list_alt,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.searching ?? 'Searching',
                content: AppLocalizations.of(context)?.searchingContent ?? 'Use the search bar at the top of the main screen to find certificates by recipient name, description, or other fields.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.filteringByTags ?? 'Filtering by Tags',
                content: AppLocalizations.of(context)?.filteringByTagsContent ?? 'Tap the tag icon in the top right to filter certificates by tags. You can choose between AND/OR logic for multiple tag filters.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.certificateDetails ?? 'Certificate Details',
                content: AppLocalizations.of(context)?.certificateDetailsContent ?? 'Tap on any certificate in the list to view its complete details, including all fields and verification status.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.qrCode ?? 'QR Code',
                content: AppLocalizations.of(context)?.qrCodeContent ?? 'Use the QR code button on a certificate to generate a QR code containing the certificate hash for easy verification.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.deleting ?? 'Deleting',
                content: AppLocalizations.of(context)?.deletingContent ?? 'Swipe left on a certificate or use the delete button to remove it from your collection.',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.batchOperations ?? 'Batch Operations',
            icon: Icons.batch_prediction,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.multiSelectMode ?? 'Multi-select Mode',
                content: AppLocalizations.of(context)?.multiSelectModeContent ?? 'Long press on any certificate to enter multi-select mode. Then tap on other certificates to select multiple items.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.batchTagUpdates ?? 'Batch Tag Updates',
                content: AppLocalizations.of(context)?.batchTagUpdatesContent ?? 'In multi-select mode, tap the tag icon to update tags for all selected certificates at once.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.csvExport ?? 'CSV Export',
                content: AppLocalizations.of(context)?.csvExportContent ?? 'In multi-select mode, tap the download icon to export all selected certificates to a CSV file that can be used for re-import.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.batchDelete ?? 'Batch Delete',
                content: AppLocalizations.of(context)?.batchDeleteContent ?? 'In multi-select mode, tap the delete icon to remove all selected certificates at once.',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.verificationBlockchain ?? 'Verification & Blockchain',
            icon: Icons.verified,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.certificateHash ?? 'Certificate Hash',
                content: AppLocalizations.of(context)?.certificateHashContent ?? 'Each certificate has a unique deterministic hash generated based on its content. This hash ensures the certificate cannot be tampered with.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.electrumXConnection ?? 'ElectrumX Connection',
                content: AppLocalizations.of(context)?.electrumXConnectionContent ?? 'Configure your ElectrumX server connection in the Settings screen to verify certificates against blockchain records.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.verificationStatus ?? 'Verification Status',
                content: AppLocalizations.of(context)?.verificationStatusContent ?? 'Certificates that have been registered on the blockchain will show a verification badge with the number of confirmations.',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.settings ?? 'Settings',
            icon: Icons.settings,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.electrumXServer ?? 'ElectrumX Server',
                content: AppLocalizations.of(context)?.electrumXServerContent ?? 'Configure the ElectrumX server connection details including host, port, and protocol.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.themeSettings ?? 'Theme Settings',
                content: AppLocalizations.of(context)?.themeSettingsContent ?? 'Change between light and dark themes or use system default.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.languageSettings ?? 'Language Settings',
                content: AppLocalizations.of(context)?.languageSettingsContent ?? 'Choose your preferred language for the application interface.',
              ),
            ],
          ),
          
          _buildSection(
            title: AppLocalizations.of(context)?.storageInformation ?? 'Storage Information',
            content: AppLocalizations.of(context)?.storageInformationContent ?? 'Certificate data is stored locally on your device in the application\'s documents directory. The app can efficiently handle thousands of certificates, but performance may decrease with very large collections.',
            icon: Icons.storage,
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.exportDirectories ?? 'Export Directories',
            icon: Icons.folder_special,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.exportLocation ?? 'Export Location',
                content: AppLocalizations.of(context)?.exportLocationContent ?? 'All exported files (certificates and CSV exports) are saved to a dedicated "KbucCertifier" folder for easy access.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.windowsPath ?? 'Windows',
                content: AppLocalizations.of(context)?.windowsPathContent ?? 'C:\\Users\\Username\\Documents\\KbucCertifier\\',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.macOSPath ?? 'macOS',
                content: AppLocalizations.of(context)?.macOSPathContent ?? '/Users/Username/Documents/KbucCertifier/',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.linuxPath ?? 'Linux',
                content: AppLocalizations.of(context)?.linuxPathContent ?? '/home/username/Documents/KbucCertifier/',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.androidPath ?? 'Android',
                content: AppLocalizations.of(context)?.androidPathContent ?? 'In the Downloads/KbucCertifier folder in your device storage.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.iOSPath ?? 'iOS',
                content: AppLocalizations.of(context)?.iOSPathContent ?? 'In the app\'s documents directory under KbucCertifier folder.',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.blockchainIntegration ?? 'Blockchain Integration',
            icon: Icons.link,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.privacyPreservingVerification ?? 'Privacy-Preserving Verification',
                content: AppLocalizations.of(context)?.privacyPreservingVerificationContent ?? 'Only a cryptographic hash of the certificate data is recorded on-chain. The actual content remains off-chain, preserving privacy while allowing public verification.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.immutableIssuerIdentity ?? 'Immutable Issuer Identity',
                content: AppLocalizations.of(context)?.immutableIssuerIdentityContent ?? 'Each certificate is permanently linked to a blockchain-based identity representing the issuing institution, preventing forgery and ensuring trust.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.delegatedCertificateIssuance ?? 'Delegated Certificate Issuance',
                content: AppLocalizations.of(context)?.delegatedCertificateIssuanceContent ?? 'Issuance can be done via a delegated profile that represents the institution rather than a personal cryptographic key, ensuring institutional continuity.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.certificateOwnership ?? 'Certificate Ownership',
                content: AppLocalizations.of(context)?.certificateOwnershipContent ?? 'Students may optionally receive on-chain ownership of their certificates, enhancing control and portability without requiring it for verification.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.implementationProcess ?? 'Implementation Process',
                content: AppLocalizations.of(context)?.implementationProcessContent ?? '1. Configure a blockchain-based identity for the institution\n2. Delegate issuance rights to a controlled profile\n3. Use this app to generate and hash certificate content\n4. Register the hash and metadata to the blockchain\n5. Export certificate data for the recipient to store or share',
              ),
            ],
          ),
          
          _buildExpandableSection(
            context: context,
            title: AppLocalizations.of(context)?.aboutKbunetNetwork ?? 'About KBUNET Network',
            icon: Icons.public,
            children: [
              _buildSubsection(
                title: AppLocalizations.of(context)?.decentralizedIdentities ?? 'Decentralized Identities (DIDs)',
                content: AppLocalizations.of(context)?.decentralizedIdentitiesContent ?? 'KBUNET provides secure, blockchain-verified digital identities directly connected to your wallet, ensuring ownership and control over your digital self with on-chain profiles and a comprehensive reputation system.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.web3ContentManagement ?? 'Web3 Content Management',
                content: AppLocalizations.of(context)?.web3ContentManagementContent ?? 'Create and secure NFTs locally with the W3CM app, enabling offline content creation and direct blockchain registration without third parties. This app is part of the KBUNET ecosystem for certificate management.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.reputationPoints ?? 'Reputation Points (RPs)',
                content: AppLocalizations.of(context)?.reputationPointsContent ?? 'Earn and build Reputation Points through network participation, creating a trustless system for evaluating user credibility and institution trustworthiness.',
              ),
              _buildSubsection(
                title: AppLocalizations.of(context)?.multipleProfileTypes ?? 'Multiple Profile Types',
                content: AppLocalizations.of(context)?.multipleProfileTypesContent ?? 'Choose from various profile types including Identity, NFTs, and Domains, each with specific features suited to different use cases including certificate issuance.',
              ),
            ],
          ),
          
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.officialWebsite ?? 'Official Website',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final Uri url = Uri.parse('https://kbunet.net/certification');
                      if (!await launchUrl(url)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch $url')),
                        );
                      }
                    },
                    child: Text(
                      'https://kbunet.net/certification',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              AppLocalizations.of(context)?.appVersion ?? 'W3 Certificate Manager v1.0',
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
