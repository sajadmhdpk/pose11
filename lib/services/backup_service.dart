import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String fileName = 'platano_pos_backup.json';
  static const String folderName = 'Platano_POS';
  static const MethodChannel _storageChannel = MethodChannel('com.example.pose1/storage');

  static DateTime? _lastBackupTime;
  static String? _lastBackupPath;

  static DateTime? get lastBackupTime => _lastBackupTime;
  static String? get lastBackupPath => _lastBackupPath;

  /// Check if Android 11+ has granted MANAGE_EXTERNAL_STORAGE
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _storageChannel.invokeMethod<bool>('hasStoragePermission');
      return result ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Open Android settings so user can enable All Files Access for Platano POS
  static Future<void> requestStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _storageChannel.invokeMethod('requestStoragePermission');
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
    }
  }

  /// Candidate external directories that survive app uninstallation
  static Future<List<Directory>> getCandidateBackupDirectories() async {
    final List<Directory> dirs = [];

    if (kIsWeb) return dirs;

    if (Platform.isAndroid) {
      // 1. Android public Download directory
      dirs.add(Directory('/storage/emulated/0/Download/$folderName'));
      // 2. Android public Documents directory
      dirs.add(Directory('/storage/emulated/0/Documents/$folderName'));
      // 3. Android Root external storage folder
      dirs.add(Directory('/storage/emulated/0/$folderName'));
      // 4. Direct public Download without subfolder
      dirs.add(Directory('/storage/emulated/0/Download'));

      // 5. App External Files Directory (survives app updates, on phone physical storage)
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          dirs.add(Directory('${extDir.path}/$folderName'));
        }
      } catch (_) {}
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dirs.add(Directory('$userProfile\\Documents\\$folderName'));
        dirs.add(Directory('$userProfile\\Downloads\\$folderName'));
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        dirs.add(Directory('$home/Documents/$folderName'));
        dirs.add(Directory('$home/Downloads/$folderName'));
      }
    }

    try {
      final appDocs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${appDocs.path}/$folderName'));
    } catch (_) {}

    return dirs;
  }

  /// Directory specifically for permanent product images
  static Future<Directory> getPermanentImagesDir() async {
    final candidateDirs = await getCandidateBackupDirectories();
    for (final dir in candidateDirs) {
      try {
        final imgDir = Directory('${dir.path}/images');
        if (!imgDir.existsSync()) {
          imgDir.createSync(recursive: true);
        }
        // Test write capability
        final testFile = File('${imgDir.path}/.test');
        testFile.writeAsStringSync('ok');
        testFile.deleteSync();
        return imgDir;
      } catch (e) {
        debugPrint('Could not create/write images folder in ${dir.path}: $e');
      }
    }
    // Fallback to app documents directory
    final appDocs = await getApplicationDocumentsDirectory();
    final fallback = Directory('${appDocs.path}/$folderName/images');
    if (!fallback.existsSync()) {
      fallback.createSync(recursive: true);
    }
    return fallback;
  }

  /// Copies image from temporary picker path to permanent Platano_POS/images folder
  static Future<String?> persistImageFile(String sourcePath, String productId) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) return null;

      final targetDir = await getPermanentImagesDir();
      final cleanId = productId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final ext = sourcePath.contains('.') ? '.${sourcePath.split('.').last}' : '.jpg';
      final targetFile = File('${targetDir.path}/img_$cleanId$ext');

      // If already same path, no need to copy
      if (src.path == targetFile.path) return targetFile.path;

      await src.copy(targetFile.path);
      debugPrint('Persisted product image to: ${targetFile.path}');
      return targetFile.path;
    } catch (e) {
      debugPrint('Error persisting image file: $e');
      return sourcePath;
    }
  }

  /// Convert image file to Base64 string for embedding in backup
  static Future<String?> imageFileToBase64(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
    }
    return null;
  }

  /// Restores an image from Base64 string and saves it to permanent storage
  static Future<String?> restoreImageFromBase64(String base64Str, String productId) async {
    try {
      final bytes = base64Decode(base64Str);
      final targetDir = await getPermanentImagesDir();
      final cleanId = productId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetFile = File('${targetDir.path}/img_$cleanId.jpg');
      await targetFile.writeAsBytes(bytes);
      debugPrint('Restored image from Base64 to: ${targetFile.path}');
      return targetFile.path;
    } catch (e) {
      debugPrint('Error restoring image from Base64: $e');
      return null;
    }
  }

  /// Resolves an existing image path or restores from base64 / candidate directories
  static Future<String?> resolveOrRestoreImage({
    required String productId,
    String? originalPath,
    String? base64Data,
  }) async {
    // 1. If original file exists, return it
    if (originalPath != null && originalPath.isNotEmpty) {
      final file = File(originalPath);
      if (file.existsSync()) {
        return originalPath;
      }
    }

    // 2. If Base64 data is present in backup, restore file from it
    if (base64Data != null && base64Data.trim().isNotEmpty) {
      final restored = await restoreImageFromBase64(base64Data, productId);
      if (restored != null && File(restored).existsSync()) {
        return restored;
      }
    }

    // 3. Search in candidate Platano_POS/images directories
    final cleanId = productId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final candidateDirs = await getCandidateBackupDirectories();
    for (final baseDir in candidateDirs) {
      try {
        final imagesDir = Directory('${baseDir.path}/images');
        if (imagesDir.existsSync()) {
          // Check for img_$cleanId.jpg
          final expected = File('${imagesDir.path}/img_$cleanId.jpg');
          if (expected.existsSync()) return expected.path;

          // Check if original basename exists
          if (originalPath != null && originalPath.isNotEmpty) {
            final fileName = originalPath.split(Platform.isWindows ? '\\' : '/').last;
            final match = File('${imagesDir.path}/$fileName');
            if (match.existsSync()) return match.path;
          }

          // Check any file matching the product id
          final list = imagesDir.listSync();
          for (final entity in list) {
            if (entity is File && entity.path.contains(cleanId)) {
              return entity.path;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Automatically save backup to phone storage across all available locations
  static Future<File?> autoSaveBackup(Map<String, dynamic> fullData) async {
    if (kIsWeb) return null;

    final jsonContent = const JsonEncoder.withIndent('  ').convert(fullData);
    final candidateDirs = await getCandidateBackupDirectories();

    File? savedFile;
    for (final dir in candidateDirs) {
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonContent, flush: true);

        if (file.existsSync() && file.lengthSync() > 10) {
          _lastBackupTime = DateTime.now();
          _lastBackupPath = file.path;
          savedFile ??= file;
          debugPrint('Backup saved to: ${file.path} (${file.lengthSync()} bytes)');
        }
      } catch (e) {
        debugPrint('Could not write backup to ${dir.path}: $e');
      }
    }
    return savedFile;
  }

  /// Automatically check and load backup if app was uninstalled and reinstalled
  static Future<Map<String, dynamic>?> findExistingBackup() async {
    if (kIsWeb) return null;

    final candidateDirs = await getCandidateBackupDirectories();
    for (final dir in candidateDirs) {
      try {
        final file = File('${dir.path}/$fileName');
        if (file.existsSync()) {
          final content = await file.readAsString();
          if (content.trim().isNotEmpty) {
            final decoded = jsonDecode(content);
            if (decoded is Map<String, dynamic>) {
              final products = decoded['products'] as List?;
              // Verify backup has content
              if (products != null) {
                _lastBackupPath = file.path;
                _lastBackupTime = file.lastModifiedSync();
                debugPrint('Found existing phone backup at: ${file.path}');
                return decoded;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error reading backup from ${dir.path}: $e');
      }
    }
    return null;
  }

  /// Get backup info for user display
  static Future<Map<String, dynamic>> getBackupInfo() async {
    final existing = await findExistingBackup();
    final hasPerm = await hasStoragePermission();

    if (existing == null) {
      return {
        'exists': false,
        'path': null,
        'time': null,
        'productsCount': 0,
        'invoicesCount': 0,
        'hasPermission': hasPerm,
        'isPublic': false,
      };
    }

    final pCount = (existing['products'] as List?)?.length ?? 0;
    final invCount = (existing['invoices'] as List?)?.length ?? 0;
    final path = _lastBackupPath ?? '';
    final isPublic = path.contains('/Download') ||
        path.contains('/Documents') ||
        path.contains('\\Downloads') ||
        path.contains('\\Documents');

    return {
      'exists': true,
      'path': _lastBackupPath,
      'time': _lastBackupTime,
      'productsCount': pCount,
      'invoicesCount': invCount,
      'hasPermission': hasPerm,
      'isPublic': isPublic,
    };
  }
}
