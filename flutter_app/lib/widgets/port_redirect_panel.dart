import 'package:flutter/material.dart';

class PortRedirectPanel extends StatefulWidget {
  const PortRedirectPanel({
    super.key,
    required this.onEnable,
    required this.onDisable,
  });

  final Future<void> Function(int targetPort) onEnable;
  final Future<void> Function(int targetPort) onDisable;

  @override
  State<PortRedirectPanel> createState() => _PortRedirectPanelState();
}

class _PortRedirectPanelState extends State<PortRedirectPanel> {
  final _controller = TextEditingController(text: '3000');
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply(Future<void> Function(int) action) async {
    final port = int.tryParse(_controller.text.trim());
    if (port == null) return;
    setState(() => _busy = true);
    try {
      await action(port);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecció actualitzada')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Redirecció del port 80', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port de destí', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton(onPressed: _busy ? null : () => _apply(widget.onEnable), child: const Text('Configurar')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _busy ? null : () => _apply(widget.onDisable), child: const Text('Desconfigurar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
