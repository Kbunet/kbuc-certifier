# KbucCertifier - Blockchain-Based Certificate Management

## Overview
KbucCertifier is a comprehensive cross-platform application designed for academic institutions and organizations to create, manage, and verify digital certificates using blockchain technology. Built on the W3CertificateStandard, it provides a secure and tamper-proof solution for issuing and managing digital credentials with a focus on ownership verification, portability, and blockchain integration.

## Key Features
- **Certificate Management**: Create, import, export, and organize digital certificates
- **Blockchain Integration**: Connect to Electrum nodes for certificate verification and registration
- **Multi-language Support**: Available in English and Arabic
- **Cross-Platform**: Available on Android, iOS, Windows, macOS, and Linux
- **Advanced Search & Filtering**: Find and filter certificates by name, recipient, issuer, tags, and more
- **Batch Operations**: Select multiple certificates for bulk actions like export to CSV
- **Secure Storage**: Local encryption for certificate security
- **Dedicated Export Directory**: All exported files are saved to a dedicated 'KbucCertifier' folder in the user's Documents directory

## Technical Details
- Built with Flutter for cross-platform compatibility
- Implements certificate hashing and blockchain verification
- Provides portable content format (.pcontent) for easy sharing and backup
- CSV import/export functionality with UTF-8 support for international characters
- Dark and light theme support
- Responsive design for various screen sizes

## Getting Started
1. Launch the application
2. Connect to an Electrum node (optional)
3. Import existing certificates or create new ones
4. Use the search and filter functionality to find specific certificates
5. Export certificates to CSV or .pcontent format

## Export Directory
All exported files (certificates and CSV exports) are saved to:
- Windows: `C:\Users\Username\Documents\KbucCertifier\`
- macOS: `/Users/Username/Documents/KbucCertifier/`
- Linux: `/home/username/Documents/KbucCertifier/`
- Android: In the Downloads/KbucCertifier folder
- iOS: In the app's documents directory under KbucCertifier

## System Requirements
- Windows 10 or later
- macOS 10.14 or later
- Linux (with GTK 3)
- Android 5.0 or later
- iOS 12.0 or later

## License
Copyright © 2025 KBU Network. All rights reserved.
2. Configure your node settings (optional)
3. Start creating or importing content
4. Use the search and filter functions to manage your content library

## Development
This application is in active development. Current version: 0.1.0
