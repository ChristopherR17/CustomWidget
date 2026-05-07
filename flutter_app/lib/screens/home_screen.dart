import 'package:flutter/material.dart';

import '../models/ssh_profile.dart';
import '../services/profile_store.dart';
import '../services/ssh_workspace.dart';
import '../widgets/nested_selectable_list.dart';
import '../widgets/titled_text_field.dart';
import 'remote_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = ProfileStore();
  final _workspace = SshWorkspace();
  final _alias = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _key = TextEditingController();

  List<SshProfile> _profiles = [];
  SshProfile? _selected;
  bool _loading = true;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _alias.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _key.dispose();
    _workspace.close();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _store.load();
    setState(() {
      _profiles = profiles;
      _loading = false;
      if (profiles.isNotEmpty) _select(profiles.first);
    });
  }

  void _select(SshProfile profile) {
    _selected = profile;
    _alias.text = profile.alias;
    _host.text = profile.host;
    _port.text = profile.port.toString();
    _username.text = profile.username;
    _key.text = profile.privateKeyName;
  }

  SshProfile _formProfile({int? id}) {
    return SshProfile(
      id: id ?? _selected?.id ?? _store.nextId(_profiles),
      alias: _alias.text.trim(),
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? 22,
      username: _username.text.trim(),
      privateKeyName: _key.text.trim().isEmpty ? 'id_rsa' : _key.text.trim(),
    );
  }

  Future<void> _saveCurrent() async {
    final profile = _formProfile();
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    setState(() {
      if (index == -1) {
        _profiles.add(profile);
      } else {
        _profiles[index] = profile;
      }
      _select(profile);
    });
    await _store.save(_profiles);
  }

  Future<void> _newProfile() async {
    final profile = SshProfile(
      id: _store.nextId(_profiles),
      alias: 'Nou servidor',
      host: 'ieticloudpro.ieti.cat',
      port: 22,
      username: '',
      privateKeyName: 'id_rsa',
    );
    setState(() {
      _profiles.add(profile);
      _select(profile);
    });
    await _store.save(_profiles);
  }

  Future<void> _deleteCurrent() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() {
      _profiles.removeWhere((item) => item.id == selected.id);
      if (_profiles.isNotEmpty) {
        _select(_profiles.first);
      } else {
        _selected = null;
        _alias.clear();
        _host.clear();
        _port.clear();
        _username.clear();
        _key.clear();
      }
    });
    await _store.save(_profiles);
  }

  Future<void> _connect() async {
    final profile = _formProfile();
    setState(() => _connecting = true);
    try {
      await _saveCurrent();
      await _workspace.connect(profile);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RemoteBrowserScreen(workspace: _workspace, initialPath: '/home/${profile.username}'),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de connexió: $error')));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Gestor SSH Proxmox')),
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Expanded(
                    child: NestedSelectableList<SshProfile>(
                      title: 'Servidors',
                      items: _profiles,
                      selected: _selected,
                      labelOf: (profile) => profile.alias,
                      onSelected: (profile) => setState(() => _select(profile)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: _newProfile, icon: const Icon(Icons.add), label: const Text('Afegir'))),
                        const SizedBox(width: 8),
                        IconButton(onPressed: _deleteCurrent, icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Configuració SSH', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TitledTextField(title: 'Nom', controller: _alias),
                        const SizedBox(height: 14),
                        TitledTextField(title: 'Servidor', controller: _host),
                        const SizedBox(height: 14),
                        TitledTextField(title: 'Port', controller: _port, keyboardType: TextInputType.number),
                        const SizedBox(height: 14),
                        TitledTextField(title: 'Usuari', controller: _username),
                        const SizedBox(height: 14),
                        TitledTextField(title: 'Clau', controller: _key),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(onPressed: _saveCurrent, icon: const Icon(Icons.save), label: const Text('Guardar')),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _connecting ? null : _connect,
                              icon: _connecting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.power),
                              label: const Text('Connectar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
