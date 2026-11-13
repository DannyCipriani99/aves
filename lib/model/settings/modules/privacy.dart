import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/settings/modules/history.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves_model/aves_model.dart';

mixin PrivacySettings on SettingsAccess, HistorySettings {
  // directories scanned directly from the file system, in addition to the Media Store
  // (this is the only way to get items from hidden or `.nomedia` directories)
  List<String> get scanIncludedPaths => getStringList(SettingKeys.scanIncludedPathsKey) ?? [];

  set scanIncludedPaths(List<String> newValue) => set(SettingKeys.scanIncludedPathsKey, newValue);

  // directories whose items are left out of the collection
  List<String> get scanExcludedPaths => getStringList(SettingKeys.scanExcludedPathsKey) ?? [];

  set scanExcludedPaths(List<String> newValue) => set(SettingKeys.scanExcludedPathsKey, newValue);

  // whether the file system scan of included paths goes into hidden (dot-prefixed) subdirectories
  bool get scanHiddenFolders => getBool(SettingKeys.scanHiddenFoldersKey) ?? SettingsDefaults.scanHiddenFolders;

  set scanHiddenFolders(bool newValue) => set(SettingKeys.scanHiddenFoldersKey, newValue);

  static String _asDirPrefix(String dirPath) => dirPath.endsWith('/') ? dirPath : '$dirPath/';

  // `true` if `path` is below one of the included directories, and not under a hidden (dot-prefixed) sub-path
  // (unless hidden folders are scanned)
  bool isPathIncludedInScan(String path) {
    final hiddenAllowed = scanHiddenFolders;
    return scanIncludedPaths.any((dirPath) {
      final prefix = _asDirPrefix(dirPath);
      if (!path.startsWith(prefix)) return false;
      if (hiddenAllowed) return true;
      return !path.substring(prefix.length).split('/').any((segment) => segment.startsWith('.'));
    });
  }

  static int _longestMatchingPrefix(List<String> dirs, String path) {
    var best = -1;
    for (final dir in dirs) {
      final prefix = _asDirPrefix(dir);
      if (prefix.length > best && path.startsWith(prefix)) best = prefix.length;
    }
    return best;
  }

  // Returns a test telling whether an item path is left out of the collection, according to the scan rules:
  // - the most specific folder rule wins, so a folder included inside an excluded one is still shown,
  //   (e.g. exclude `/storage/emulated/0`, include `/storage/emulated/0/Ex` => only `Ex` is shown)
  // - when hidden folders are not shown, items in dot-prefixed folders are left out
  //   (relative to the included folder when there is one, otherwise to the storage volume root)
  // The lists are read once, so this is cheap to call for many paths.
  bool Function(String? path) scanPathExcluder() {
    final excluded = scanExcludedPaths;
    final included = scanIncludedPaths;
    final showHidden = scanHiddenFolders;
    if (excluded.isEmpty && included.isEmpty && showHidden) return (_) => false;

    return (path) {
      if (path == null) return false;
      final excludedLen = _longestMatchingPrefix(excluded, path);
      final includedLen = _longestMatchingPrefix(included, path);
      if (excludedLen > includedLen) return true;
      if (!showHidden && !path.startsWith(androidFileUtils.vaultRoot)) {
        int? rootLen;
        if (includedLen >= 0) {
          rootLen = includedLen;
        } else {
          final volumePath = androidFileUtils.getStorageVolume(path)?.path;
          if (volumePath != null) rootLen = _asDirPrefix(volumePath).length;
        }
        if (rootLen != null && rootLen <= path.length) {
          final segments = path.substring(rootLen).split('/');
          // the last segment is the file name
          if (segments.length > 1 && segments.take(segments.length - 1).any((segment) => segment.startsWith('.'))) return true;
        }
      }
      return false;
    };
  }

  bool isPathExcludedFromScan(String? path) => scanPathExcluder()(path);

  Set<CollectionFilter> get hiddenFilters => (getStringList(SettingKeys.hiddenFiltersKey) ?? []).map(CollectionFilter.fromJson).nonNulls.toSet();

  set hiddenFilters(Set<CollectionFilter> newValue) => set(SettingKeys.hiddenFiltersKey, newValue.map((filter) => filter.toJsonString()).toList());

  void changeFilterVisibility(Set<CollectionFilter> filters, bool visible) {
    final _deactivatedHiddenFilters = deactivatedHiddenFilters;
    final _hiddenFilters = hiddenFilters;

    _deactivatedHiddenFilters.removeAll(filters);
    if (visible) {
      _hiddenFilters.removeAll(filters);
    } else {
      _hiddenFilters.addAll(filters);
      searchHistory = searchHistory..removeWhere(filters.contains);
    }

    deactivatedHiddenFilters = _deactivatedHiddenFilters;
    hiddenFilters = _hiddenFilters;
  }

  Set<CollectionFilter> get deactivatedHiddenFilters => (getStringList(SettingKeys.deactivatedHiddenFiltersKey) ?? []).map(CollectionFilter.fromJson).nonNulls.toSet();

  set deactivatedHiddenFilters(Set<CollectionFilter> newValue) => set(SettingKeys.deactivatedHiddenFiltersKey, newValue.map((filter) => filter.toJsonString()).toList());

  void activateHiddenFilter(CollectionFilter filter, bool active) {
    final _deactivatedHiddenFilters = deactivatedHiddenFilters;
    final _hiddenFilters = hiddenFilters;

    if (active) {
      _deactivatedHiddenFilters.remove(filter);
      _hiddenFilters.add(filter);
      searchHistory = searchHistory..remove(filter);
    } else {
      _deactivatedHiddenFilters.add(filter);
      _hiddenFilters.remove(filter);
    }

    deactivatedHiddenFilters = _deactivatedHiddenFilters;
    hiddenFilters = _hiddenFilters;
  }
}
