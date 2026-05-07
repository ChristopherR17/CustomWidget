import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/app_logger.dart';
import '../services/ssh_file_gateway.dart';
import '../state/remote_session_state.dart';
import '../theme/app_palette.dart';
import 'remote_node_details_screen.dart';

class RemoteExplorerScreen extends StatefulWidget {
  final SshFileGateway manager;

  const RemoteExplorerScreen({super.key, required this.manager});

  @override
  State<RemoteExplorerScreen> createState() => _RemoteExplorerScreenState();
}

class _RemoteExplorerScreenState extends State<RemoteExplorerScreen> {
  void _navigateTo(String path) async {
    final cleanPath = p.normalize(path);
    selectedRemotePath = cleanPath;
    await widget.manager.fetchDirectory(cleanPath);
    if (mounted) setState(() {});
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final filePath = result.files.single.path;

      if (filePath != null) {
        await widget.manager.uploadRemoteFile(filePath, selectedRemotePath);
        await widget.manager.fetchDirectory(selectedRemotePath);

        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo subido correctamente')),
        );
      }
    }
  }

  void _openDetails(int index) {
    final file = remoteNodes[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RemoteNodeDetailsScreen(
          manager: widget.manager,
          file: file,
        ),
      ),
    ).then((_) async {
      await widget.manager.fetchDirectory(selectedRemotePath);
      if (mounted) setState(() {});
    });
  }

  Widget _nodeRow(int index) {
    final file = remoteNodes[index];
    final icon = file.isDirectory ? Icons.folder_rounded : Icons.insert_drive_file_rounded;
    final iconColor = file.isDirectory ? AppPalette.primary : AppPalette.accent;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        minVerticalPadding: 14,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          file.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppPalette.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          file.permissions,
          style: const TextStyle(
            color: AppPalette.textMuted,
            fontFamily: 'monospace',
          ),
        ),
        trailing: IconButton(
          tooltip: 'Opciones',
          icon: const Icon(Icons.more_horiz_rounded),
          onPressed: () => _openDetails(index),
        ),
        onTap: () {
          if (file.isDirectory) {
            logger.i('Entrando en: ${file.name}');

            if (file.name == '..') {
              _navigateTo(p.dirname(selectedRemotePath));
            } else {
              _navigateTo(p.join(selectedRemotePath, file.name));
            }
          } else {
            _openDetails(index);
          }
        },
        onLongPress: () => _openDetails(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Row(
        children: [
          Container(
            width: 270,
            height: double.infinity,
            color: AppPalette.sidebar,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Explorador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ruta actual:',
                  style: TextStyle(color: Colors.white.withOpacity(0.55)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.sidebarCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    selectedRemotePath,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: AppPalette.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text(
                      'Subir archivo',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onPressed: _uploadFile,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Archivos del servidor',
                          style: TextStyle(
                            color: AppPalette.textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${remoteNodes.length} elementos',
                        style: const TextStyle(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      itemCount: remoteNodes.length,
                      itemBuilder: (context, index) => _nodeRow(index),
                    ),
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
