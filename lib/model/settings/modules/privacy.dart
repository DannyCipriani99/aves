import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/settings/modules/history.dart';
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

  // `true` if the file at `path` is located in (or below) one of the excluded directories
  bool isPathExcludedFromScan(String? path) {
    if (path == null) return false;
    final excluded = scanExcludedPaths;
    if (excluded.isEmpty) return false;
    return excluded.any((dirPath) => path.startsWith(_asDirPrefix(dirPath)));
  }

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
