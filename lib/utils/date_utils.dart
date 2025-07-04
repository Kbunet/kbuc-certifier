import 'package:intl/intl.dart';

/// Utility class for flexible date parsing and formatting
class CertificateDateUtils {
  /// List of common date formats to try parsing
  static final List<DateFormat> _dateFormats = [
    // ISO format
    DateFormat('yyyy-MM-dd'),
    // Common US format
    DateFormat('MM/dd/yyyy'),
    // Common European format
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    // Other formats
    DateFormat('MM-dd-yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('MMMM d, yyyy'),
    DateFormat('d MMMM yyyy'),
    // With time components (that we'll ignore)
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('dd/MM/yyyy HH:mm:ss'),
  ];

  /// Attempts to parse a date string in various formats and standardize it to ISO format (YYYY-MM-DD)
  ///
  /// Returns the standardized date string if successful, or null if parsing fails
  static String? parseAndStandardizeDate(String dateString) {
    // Trim any extra whitespace
    final trimmedDate = dateString.trim();
    
    // Try each format in order
    for (final format in _dateFormats) {
      try {
        final date = format.parse(trimmedDate);
        // Convert back to standard ISO format
        return DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        // Continue to the next format if this one fails
        continue;
      }
    }
    
    // If that didn't work, try a more flexible approach using DateTime.tryParse
    try {
      final date = DateTime.tryParse(trimmedDate);
      if (date != null) {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (_) {
      // Ignore and continue
    }
    
    // If all parsing attempts fail, return null
    return null;
  }

  /// Validates if a given date string is in ISO format (YYYY-MM-DD)
  static bool isIsoDateFormat(String dateString) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return regex.hasMatch(dateString);
  }
}
