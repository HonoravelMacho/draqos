import 'package:draqos_core/draqos_core.dart';
import 'package:draqos_ui/draqos_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_controller.dart';
import 'session.dart';

/// Create / edit a dynamic QR: id, metadata, destination, style.
/// The QR image itself encodes the STABLE public URL; editing the
/// destination never changes the printed code.
class DynamicEditorScreen extends ConsumerStatefulWidget {
  final DynamicQr? existing;
  const DynamicEditorScreen({super.key, this.existing});

  @override
  ConsumerState<DynamicEditorScreen> createState() =>
      _DynamicEditorScreenState();
}

class _DynamicEditorScreenState extends ConsumerState<DynamicEditorScreen> {
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _dest;
  late bool _active;
  late final EditorController _style;
  bool _styleInit = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = TextEditingController(text: e?.id ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _dest = TextEditingController(text: e?.destinationUrl ?? 'https://');
    _active = e?.active ?? true;
    _style = EditorController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_styleInit) {
      _styleInit = true;
      final e = widget.existing;
      if (e != null) {
        try {
          _style.loadStyle(QrStyle.decode(e.styleJson));
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _desc.dispose();
    _dest.dispose();
    _style.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'NEW DYNAMIC QR' : 'EDIT /r/${widget.existing!.id}',
        ),
      ),
      body: repo == null
          ? const Center(child: Text('Pair first (Pair tab).'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isNew)
                    TextField(
                      controller: _id,
                      decoration: const InputDecoration(
                        labelText:
                            'Short id (blank = random, 3-32 URL-safe chars)',
                      ),
                    ),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: _desc,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: _dest,
                    decoration: const InputDecoration(
                      labelText: 'Destination URL (editable later)',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('STYLE (re-editable, stored as JSON)'),
                  ListenableBuilder(
                    listenable: _style,
                    builder: (context, _) => Column(
                      children: [
                        DraqSegmented<ModuleShape>(
                          options: ModuleShape.values,
                          value: _style.moduleShape,
                          onChanged: _style.setModuleShape,
                          labelOf: (v) => v.name,
                        ),
                        DraqSegmented<FramePreset>(
                          options: FramePreset.values,
                          value: _style.framePreset,
                          onChanged: _style.setFramePreset,
                          labelOf: (v) => v.name,
                        ),
                        SwitchListTile(
                          title: const Text('Auto contrast'),
                          value: _style.autoContrast,
                          onChanged: _style.setAutoContrast,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DraqButton(
                    label: isNew ? 'Create' : 'Save',
                    onPressed: () => _save(context, repo),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save(BuildContext context, DynamicQrRepository repo) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final input = DynamicQrInput(
      name: _name.text,
      description: _desc.text,
      destinationUrl: _dest.text.trim(),
      styleJson: _style.buildStyle().encode(),
      active: _active,
    );
    try {
      if (widget.existing == null) {
        final id = _id.text.trim().isEmpty ? _randomId() : _id.text.trim();
        final res = await repo.create(id, input);
        if (res is Err<DynamicQr>) {
          messenger.showSnackBar(
            SnackBar(content: Text('Create failed: ${res.message}')),
          );
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text('Created /r/$id — print it!')),
        );
      } else {
        final res = await repo.update(widget.existing!.id, input);
        if (res is Err<DynamicQr>) {
          messenger.showSnackBar(
            SnackBar(content: Text('Save failed: ${res.message}')),
          );
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved — QR code unchanged.')),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is DaemonUnreachable ? (e.message) : 'Save failed: $e',
          ),
        ),
      );
    }
  }

  String _randomId() {
    const abc =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    var n = now;
    var s = '';
    for (var i = 0; i < 8; i++) {
      s += abc[n % abc.length];
      n ~/= abc.length + 7;
    }
    return s;
  }
}
