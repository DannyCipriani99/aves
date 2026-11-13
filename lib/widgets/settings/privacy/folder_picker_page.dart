import 'dart:io';

import 'package:aves/theme/icons.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

// Built-in folder browser, so that any folder (e.g. `Download`, hidden folders) can be picked
// without relying on the system file picker. Needs "All files access" to list directories.
// Pops with the selected directory path.
class FolderPickerPage extends StatefulWidget {
  const FolderPickerPage({super.key, this.initialPath});

  final String? initialPath;

  static const routeName = '/settings/folder_picker';

  static Future<String?> pick(BuildContext context, {String? initialPath}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => FolderPickerPage(initialPath: initialPath),
      ),
    );
  }

  @override
  State<FolderPickerPage> createState() => _FolderPickerPageState();
}

class _FolderPickerPageState extends State<FolderPickerPage> {
  late String _currentPath;
  List<Directory> _subDirs = [];
  String? _error;
  bool _loading = false;

  static String _trim(String path) => path.length > 1 && path.endsWith('/') ? path.substring(0, path.length - 1) : path;

  List<String> get _roots => androidFileUtils.storageVolumes.map((v) => _trim(v.path)).toList();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPath;
    _currentPath = _trim(initial ?? (androidFileUtils.primaryStorage.isNotEmpty ? androidFileUtils.primaryStorage : '/storage/emulated/0'));
    _load(_currentPath);
  }

  Future<void> _load(String path) async {
    setState(() => _loading = true);
    try {
      final dir = Directory(path);
      final dirs = <Directory>[];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) dirs.add(entity);
      }
      dirs.sort((a, b) => _name(a.path).toLowerCase().compareTo(_name(b.path).toLowerCase()));
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _subDirs = dirs;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentPath = path;
        _subDirs = [];
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static String _name(String path) => path.substring(path.lastIndexOf('/') + 1);

  bool get _canGoUp => !_roots.contains(_currentPath) && _currentPath != '/';

  void _goUp() {
    final i = _currentPath.lastIndexOf('/');
    if (i > 0) _load(_currentPath.substring(0, i));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final shortcuts = <MapEntry<String, String>>[];
    for (final root in _roots) {
      shortcuts.add(MapEntry(root, root));
      shortcuts.add(MapEntry('Download', '$root/Download'));
    }

    return AvesScaffold(
      appBar: AppBar(title: Text(l10n.settingsScanPickFolderTitle)),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: shortcuts
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(AIcons.folder, size: 18),
                          label: Text(e.key == e.value ? e.value : e.key),
                          onPressed: () => _load(e.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            ListTile(
              dense: true,
              leading: IconButton(
                icon: const Icon(AIcons.goUp),
                onPressed: _canGoUp ? _goUp : null,
              ),
              title: SelectableText(_currentPath, style: theme.textTheme.bodyMedium),
              trailing: IconButton(
                icon: const Icon(AIcons.refresh),
                tooltip: l10n.settingsScanRefreshTooltip,
                onPressed: () => _load(_currentPath),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.settingsScanFolderUnreadable),
                    )
                  : _subDirs.isEmpty
                  ? Center(child: Text(l10n.settingsScanNoSubfolders))
                  : ListView.builder(
                      itemCount: _subDirs.length,
                      itemBuilder: (context, index) {
                        final path = _subDirs[index].path;
                        final name = _name(path);
                        final hidden = name.startsWith('.');
                        return ListTile(
                          leading: Icon(hidden ? AIcons.hide : AIcons.folder),
                          title: Text(
                            name,
                            style: hidden ? TextStyle(color: theme.disabledColor) : null,
                          ),
                          onTap: () => _load(path),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(AIcons.checked),
                  label: Text(l10n.settingsScanSelectThisFolder),
                  onPressed: _error != null ? null : () => Navigator.of(context).pop(_currentPath),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
