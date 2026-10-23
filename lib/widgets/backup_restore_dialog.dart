import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/billing_manager.dart';
import '../services/backup_service.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> with WidgetsBindingObserver {
  final BillingManager _billingManager = BillingManager();
  bool _isLoading = false;
  Map<String, dynamic> _backupInfo = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBackupInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBackupInfo();
    }
  }

  Future<void> _loadBackupInfo() async {
    final info = await BackupService.getBackupInfo();
    if (mounted) {
      setState(() => _backupInfo = info);
    }
  }

  Future<void> _triggerManualBackup() async {
    setState(() => _isLoading = true);
    try {
      final hasPerm = await BackupService.hasStoragePermission();
      if (!hasPerm) {
        if (mounted) {
          final grant = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.folder_shared_rounded, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Storage Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: const Text(
                'To save your backup in Phone Storage (Download/Platano_POS) so it survives uninstall & reinstall, Platano POS needs "All Files Access".\n\nWould you like to enable it now?',
                style: TextStyle(fontSize: 13.5, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Later'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade800),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (grant == true) {
            await BackupService.requestStoragePermission();
            await Future.delayed(const Duration(milliseconds: 600));
          }
        }
      }

      await _billingManager.triggerManualBackup();
      await _loadBackupInfo();

      if (mounted) {
        final path = _backupInfo['path'] as String? ?? '';
        final isPublic = _backupInfo['isPublic'] == true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPublic
                        ? 'Backup saved to Phone Storage (Download/Platano_POS)! Survives uninstall! ✅'
                        : 'Backup saved! Location: $path',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save backup: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromPhoneFile() async {
    setState(() => _isLoading = true);
    try {
      final existingBackup = await BackupService.findExistingBackup();
      if (existingBackup == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No backup file found in Phone Storage (Download/Platano_POS)! Please save a backup first or use Paste Code.'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      final result = await _billingManager.restoreBackupData(
        jsonEncode(existingBackup),
        triggerAutoSave: true,
      );
      await _loadBackupInfo();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${result['products']} products & ${result['invoices']} bills from Phone Storage! All images recovered! ✅',
            ),
            backgroundColor: Colors.teal.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not restore phone backup: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyBackupToClipboard() async {
    final jsonStr = await _billingManager.exportBackupData();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.copy_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Backup copied! Paste it in WhatsApp, Email or Notes to keep it safe forever! ✅'),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showPasteRestoreDialog() async {
    final controller = TextEditingController();
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null && clipboardData!.text!.contains('"app"')) {
      controller.text = clipboardData.text!;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore_page_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Restore Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup code below to restore all products, images, and invoices:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Paste JSON backup code here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade800),
            icon: const Icon(Icons.download_done_rounded, size: 18),
            label: const Text('Restore Now'),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                final result = await _billingManager.restoreBackupData(text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Restored ${result['products']} products & ${result['invoices']} bills successfully! ✅',
                      ),
                      backgroundColor: Colors.teal.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Invalid backup data: $e'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exists = _backupInfo['exists'] == true;
    final path = _backupInfo['path'] as String? ?? 'Phone Storage/Download/Platano_POS/';
    final pCount = _backupInfo['productsCount'] as int? ?? _billingManager.products.length;
    final invCount = _backupInfo['invoicesCount'] as int? ?? _billingManager.invoices.length;
    final hasPerm = _backupInfo['hasPermission'] != false;
    final isPublic = _backupInfo['isPublic'] == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_sync_rounded, color: Colors.teal.shade800, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Storage Backup',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Save & restore your products and bills',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Storage Permission Warning Banner (if permission not yet enabled on Android)
              if (!hasPerm)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phone Storage Access Needed',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'To make sure backups survive app uninstall & reinstall, please grant "All files access".',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade200,
                            foregroundColor: Colors.brown.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text(
                            'Enable All Files Access',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          onPressed: () async {
                            await BackupService.requestStoragePermission();
                            await Future.delayed(const Duration(seconds: 1));
                            await _loadBackupInfo();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isPublic ? 'Saved to Public Phone Storage ✅' : 'Auto-Backup Status',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.teal, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All products, photos, and bills are saved to your phone storage so you won\'t lose them even if you uninstall the app.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              path,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Backed up: $pCount Products, $invCount Bills',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.teal.shade900),
                        ),
                        if (exists)
                          const Text(
                            'File Ready ✅',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              // 1. Primary: Save Fresh Backup Now
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Save Fresh Backup to Phone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isLoading ? null : _triggerManualBackup,
              ),
              const SizedBox(height: 8),

              // 2. Secondary: Restore from Phone Storage File
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: BorderSide(color: Colors.teal.shade800, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.settings_backup_restore_rounded, size: 18, color: Colors.teal),
                label: Text(
                  'Restore from Phone Storage (File)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 13),
                ),
                onPressed: _isLoading ? null : _restoreFromPhoneFile,
              ),
              const SizedBox(height: 8),

              // 3. Sharing via Clipboard / Code
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.black87),
                      label: const Text(
                        'Copy Code',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      onPressed: _copyBackupToClipboard,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 16, color: Colors.black87),
                      label: const Text(
                        'Paste Code',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      onPressed: _showPasteRestoreDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
