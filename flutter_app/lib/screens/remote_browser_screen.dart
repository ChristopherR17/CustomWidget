import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/app_enums.dart';
import '../models/disk_node.dart';
import '../models/remote_entry.dart';
import '../services/ssh_workspace.dart';
import '../widgets/disk_usage_canvas.dart';
import '../widgets/port_redirect_panel.dart';
import '../widgets/service_badge.dart';

class RemoteBrowserScreen extends StatefulWidget {
  const RemoteBrowserScreen({super.key, required this.workspace, required this.initialPath});

  final SshWorkspace workspace;
  final String initialPath;

  @override
  State<RemoteBrowserScreen> createState() => _RemoteBrowserScreenState();
}

class _RemoteBrowserScreenState extends State<RemoteBrowserScreen> {
  late String _path;
  List<RemoteEntry> _entries = [];
  bool _busy = true;
  ProjectKind _projectKind = ProjectKind.unknown;
  RemoteServiceState _serviceState = RemoteServiceState.unknown;
  DiskNode? _diskNode;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final entries = await widget.workspace.list(_path);
      final kind = await widget.workspace.detectProject(_path);
      final state = kind == ProjectKind.unknown ? RemoteServiceState.unknown : await widget.workspace.serviceState(_path);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _projectKind = kind;
        _serviceState = state;
      });
    } catch (error) {
      if (mounted) _message('Error: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(RemoteEntry entry) async {
    if (!entry.isDirectory) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RemoteEntryDetailsScreen(workspace: widget.workspace, entry: entry, parentPath: _path, onChanged: _refresh),
      ));
      return;
    }
    setState(() => _path = p.posix.join(_path, entry.name));
    await _refresh();
  }

  Future<void> _goUp() async {
    if (_path == '/') return;
    setState(() => _path = p.posix.dirname(_path));
    await _refresh();
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    final localPath = result?.files.single.path;
    if (localPath == null) return;
    await _runBusy(() => widget.workspace.uploadFile(localPath, _path), 'Arxiu pujat');
  }

  Future<void> _uploadDirectory() async {
    final localPath = await FilePicker.platform.getDirectoryPath();
    if (localPath == null) return;
    await _runBusy(() => widget.workspace.uploadDirectoryAsZip(localPath, _path), 'Carpeta comprimida, pujada i descomprimida');
  }

  Future<void> _runBusy(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      _message(ok);
      await _refresh();
    } catch (error) {
      _message('Error: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async => _runBusy(() => widget.workspace.startService(_path, _projectKind), 'Servidor iniciat');
  Future<void> _stop() async => _runBusy(() => widget.workspace.stopService(_path), 'Servidor aturat');
  Future<void> _restart() async => _runBusy(() => widget.workspace.restartService(_path, _projectKind), 'Servidor reiniciat');

  Future<void> _loadDiskTree() async {
    setState(() => _busy = true);
    try {
      final node = await widget.workspace.diskTree(_path);
      if (mounted) setState(() => _diskNode = node);
    } catch (error) {
      _message('No s’ha pogut carregar el mapa de disc: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedName = widget.workspace.profile?.alias ?? 'Servidor';
    return Scaffold(
      appBar: AppBar(
        title: Text('Proxmox Drive · $connectedName'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () async { await widget.workspace.close(); if (mounted) Navigator.pop(context); }, icon: const Icon(Icons.power_settings_new)),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 230,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text('Vistes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const ListTile(selected: true, leading: Icon(Icons.folder), title: Text('Carpetes')),
                  const ListTile(leading: Icon(Icons.history), title: Text('Recents')),
                  const ListTile(leading: Icon(Icons.delete), title: Text('Eliminats')),
                  const Divider(),
                  ServiceBadge(state: _serviceState, kind: _projectKind),
                  const SizedBox(height: 12),
                  if (_projectKind != ProjectKind.unknown) ...[
                    FilledButton.icon(onPressed: _busy ? null : _start, icon: const Icon(Icons.play_arrow), label: const Text('Iniciar')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: _busy ? null : _stop, icon: const Icon(Icons.stop), label: const Text('Aturar')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: _busy ? null : _restart, icon: const Icon(Icons.restart_alt), label: const Text('Reiniciar')),
                    const SizedBox(height: 12),
                  ],
                  PortRedirectPanel(
                    onEnable: widget.workspace.enablePort80Redirect,
                    onDisable: widget.workspace.disablePort80Redirect,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(onPressed: _goUp, icon: const Icon(Icons.arrow_back)),
                      Expanded(child: Text(_path, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                      OutlinedButton.icon(onPressed: _loadDiskTree, icon: const Icon(Icons.donut_large), label: const Text('Mapa disc')),
                      const SizedBox(width: 8),
                      FilledButton.icon(onPressed: _uploadFile, icon: const Icon(Icons.upload_file), label: const Text('Afegir arxiu')),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(onPressed: _uploadDirectory, icon: const Icon(Icons.drive_folder_upload), label: const Text('Afegir carpeta')),
                    ],
                  ),
                ),
                if (_busy) const LinearProgressIndicator(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return ListTile(
                              leading: Icon(entry.isDirectory ? Icons.folder : entry.isZip ? Icons.folder_zip : Icons.description),
                              title: Text(entry.name),
                              subtitle: Text('${entry.permissions} · ${_formatBytes(entry.size)}'),
                              trailing: Wrap(
                                children: [
                                  IconButton(onPressed: () => widget.workspace.download(p.posix.join(_path, entry.name), isDirectory: entry.isDirectory).then((_) => _message('Descàrrega completada')), icon: const Icon(Icons.download)),
                                  IconButton(onPressed: () => _open(entry), icon: const Icon(Icons.info_outline)),
                                  IconButton(onPressed: () => _delete(entry), icon: const Icon(Icons.delete_outline)),
                                ],
                              ),
                              onDoubleTap: () => _open(entry),
                            );
                          },
                        ),
                      ),
                      if (_diskNode != null)
                        SizedBox(
                          width: 460,
                          child: Card(
                            margin: const EdgeInsets.all(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Ús de disc', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  DiskUsageCanvas(root: _diskNode!),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(RemoteEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esborrar'),
        content: Text('Vols esborrar "${entry.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel·lar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Esborrar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runBusy(() => widget.workspace.delete(p.posix.join(_path, entry.name), isDirectory: entry.isDirectory), 'Element esborrat');
  }

  String _formatBytes(int bytes) {
    if (bytes > 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class RemoteEntryDetailsScreen extends StatefulWidget {
  const RemoteEntryDetailsScreen({super.key, required this.workspace, required this.entry, required this.parentPath, required this.onChanged});

  final SshWorkspace workspace;
  final RemoteEntry entry;
  final String parentPath;
  final Future<void> Function() onChanged;

  @override
  State<RemoteEntryDetailsScreen> createState() => _RemoteEntryDetailsScreenState();
}

class _RemoteEntryDetailsScreenState extends State<RemoteEntryDetailsScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.entry.name);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final newName = _name.text.trim();
    if (newName.isEmpty || newName == widget.entry.name) return;
    setState(() => _busy = true);
    try {
      await widget.workspace.rename(p.posix.join(widget.parentPath, widget.entry.name), p.posix.join(widget.parentPath, newName));
      await widget.onChanged();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unzip() async {
    setState(() => _busy = true);
    try {
      await widget.workspace.unzipRemote(p.posix.join(widget.parentPath, widget.entry.name));
      await widget.onChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ZIP descomprimit')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Icon(entry.isDirectory ? Icons.folder : Icons.description, size: 96)),
                  const SizedBox(height: 16),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Text('Permisos: ${entry.permissions}'),
                  Text('Mida: ${entry.size} bytes'),
                  if (entry.modifiedAt != null) Text('Modificat: ${entry.modifiedAt}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(onPressed: _busy ? null : _rename, icon: const Icon(Icons.edit), label: const Text('Canviar nom')),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => widget.workspace.download(p.posix.join(widget.parentPath, entry.name), isDirectory: entry.isDirectory),
                        icon: const Icon(Icons.download),
                        label: const Text('Descarregar'),
                      ),
                      if (entry.isZip) OutlinedButton.icon(onPressed: _busy ? null : _unzip, icon: const Icon(Icons.folder_zip), label: const Text('Descomprimir')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Canvi ràpid de permisos'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(onPressed: () => widget.workspace.chmod(p.posix.join(widget.parentPath, entry.name), 'u+rwx'), child: const Text('Usuari rwx')),
                      OutlinedButton(onPressed: () => widget.workspace.chmod(p.posix.join(widget.parentPath, entry.name), 'go-rwx'), child: const Text('Privat')),
                      OutlinedButton(onPressed: () => widget.workspace.chmod(p.posix.join(widget.parentPath, entry.name), 'a+rx'), child: const Text('Executable/visible')),
                    ],
                  ),
                  if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
