import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/action_mixins/permission_aware.dart';
import 'package:aves/widgets/common/basic/divider.dart';
import 'package:aves/widgets/common/basic/font_size_icon_theme.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Lets the user pick directories to scan directly on the file system (included paths),
// directories to leave out (excluded paths), and whether hidden directories are scanned.
class ScanPathsPage extends StatelessWidget {
  const ScanPathsPage({super.key});

  static const routeName = '/settings/scan_paths';

  static const List<String> settingKeys = [
    SettingKeys.scanIncludedPathsKey,
    SettingKeys.scanExcludedPathsKey,
    SettingKeys.scanHiddenFoldersKey,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !settings.useTvLayout,
        title: Text(l10n.settingsScanPathsPageTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const FontSizeIconTheme(child: Icon(AIcons.info)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(l10n.settingsScanPathsBanner)),
                ],
              ),
            ),
            const ThinDivider(),
            SettingsSwitchListTile(
              selector: (context, s) => s.scanHiddenFolders,
              onChanged: (v) => settings.scanHiddenFolders = v,
              title: (context) => l10n.settingsScanHiddenFolders,
              subtitle: (context) => l10n.settingsScanHiddenFoldersSubtitle,
            ),
            const ThinDivider(),
            _PathListSection(
              title: l10n.settingsScanIncludedPaths,
              empty: l10n.settingsScanPathsEmpty,
              selector: (s) => s.scanIncludedPaths,
              onChanged: (v) => settings.scanIncludedPaths = v,
            ),
            const ThinDivider(),
            _PathListSection(
              title: l10n.settingsScanExcludedPaths,
              empty: l10n.settingsScanPathsEmpty,
              selector: (s) => s.scanExcludedPaths,
              onChanged: (v) => settings.scanExcludedPaths = v,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.settingsScanPathsApplyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathListSection extends StatelessWidget with PermissionAwareMixin {
  const _PathListSection({
    required this.title,
    required this.empty,
    required this.selector,
    required this.onChanged,
  });

  final String title;
  final String empty;
  final List<String> Function(Settings settings) selector;
  final void Function(List<String> paths) onChanged;

  Future<void> _add(BuildContext context) async {
    if (!await checkSystemFilePickerEnabled(context)) return;

    final dirPath = await storagePermissionService.requestSafAnyDirectoryAccess();
    if (dirPath == null) return;

    final current = selector(settings);
    if (!current.contains(dirPath)) {
      onChanged([...current, dirPath]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<Settings, List<String>>(
      selector: (context, s) => selector(s),
      shouldRebuild: (a, b) => !_sameItems(a, b),
      builder: (context, paths, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(title, style: Theme.of(context).textTheme.titleMedium),
              trailing: IconButton(
                icon: const Icon(AIcons.add),
                tooltip: context.l10n.settingsScanAddPathTooltip,
                onPressed: () => _add(context),
              ),
            ),
            if (paths.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(empty),
              )
            else
              ...paths.map(
                (path) => ListTile(
                  dense: true,
                  leading: const Icon(AIcons.folder),
                  title: Text(path),
                  trailing: IconButton(
                    icon: const Icon(AIcons.clear),
                    tooltip: context.l10n.clearTooltip,
                    onPressed: () => onChanged(paths.where((v) => v != path).toList()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _sameItems(List<String> a, List<String> b) => a.length == b.length && a.every(b.contains);
}
