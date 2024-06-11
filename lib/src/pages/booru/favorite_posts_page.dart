// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/post_tags.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/actions.dart" as booru_actions;
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class FavoritePostsPage extends StatelessWidget {
  const FavoritePostsPage({
    super.key,
    required this.state,
    this.asSliver = true,
    this.wrapGridPage = false,
    required this.db,
    required this.api,
  });

  final FavoriteBooruPageState state;
  final bool asSliver;
  final bool wrapGridPage;
  final BooruAPI api;

  final DbConn db;

  void _onPressed(
    BuildContext context,
    Booru booru,
    String t,
    SafeMode? safeMode,
  ) {
    Navigator.pop(context);

    state.searchTextController.text = t;
  }

  GridFrame<FavoritePostData> child(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridFrame<FavoritePostData>(
      key: state.state.gridKey,
      slivers: [
        CurrentGridSettingsLayout<FavoritePostData>(
          source: state.filter.backingStorage,
          progress: state.filter.progress,
          gridSeed: state.state.gridSeed,
        ),
      ],
      functionality: GridFunctionality(
        search: PageNameSearchWidget(
          leading: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu_rounded),
          ),
          trailingItems: [
            ChainedFilterIcon(
              filter: state.filter,
              controller: state.searchTextController,
              complete: api.completeTag,
              onChange: (str) => state.filter.clearRefresh(),
            ),
          ],
        ),
        settingsButton: GridSettingsButton.fromWatchable(state.gridSettings),
        registerNotifiers: (child) => OnBooruTagPressed(
          onPressed: _onPressed,
          child: child,
        ),
        selectionGlue: GlueProvider.generateOf(context)(),
        download: state.download,
        source: state.filter,
      ),
      description: GridDescription(
        actions: state.gridActions(),
        showAppBar: !asSliver,
        asSliver: asSliver,
        keybindsDescription: l10n.favoritesLabel,
        pageName: l10n.favoritesLabel,
        gridSeed: state.state.gridSeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      sliver: asSliver,
      watch: state.gridSettings.watch,
      child: wrapGridPage
          ? WrapGridPage(
              child: child(context),
            )
          : child(context),
    );
  }
}

class FavoriteBooruStateHolder extends StatefulWidget
    with DbConnHandle<DbConn> {
  const FavoriteBooruStateHolder({
    super.key,
    required this.build,
    required this.db,
  });

  final Widget Function(BuildContext context, FavoriteBooruPageState state)
      build;

  @override
  final DbConn db;

  @override
  State<FavoriteBooruStateHolder> createState() =>
      _FavoriteBooruStateHolderState();
}

class _FavoriteBooruStateHolderState extends State<FavoriteBooruStateHolder>
    with FavoriteBooruPageState<FavoriteBooruStateHolder> {
  @override
  void initState() {
    super.initState();

    initFavoriteBooruState();
  }

  @override
  void dispose() {
    disposeFavoriteBooruState();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, this);
  }
}

mixin FavoriteBooruPageState<T extends DbConnHandle<DbConn>> on State<T> {
  FavoritePostSourceService get favoritePosts => widget.db.favoritePosts;
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.favoritePosts;

  late final StreamSubscription<SettingsData?> settingsWatcher;

  final searchTextController = TextEditingController();

  Iterable<FavoritePostData> _collector(
    Map<String, Set<(int, Booru)>>? data,
  ) sync* {
    for (final ids in data!.values) {
      for (final i in ids) {
        yield favoritePosts.forIdxUnsafe((i.$1, i.$2));
      }
    }
  }

  static (Iterable<T>, dynamic) sameFavorites<T extends PostBase>(
    Iterable<T> cells,
    dynamic data_,
    bool end,
    Iterable<T> Function(Map<String, Set<(int, Booru)>>? data) collect,
    SafeMode currentSafeMode,
  ) {
    final data = (data_ as Map<String, Set<(int, Booru)>>?) ?? {};

    T? prevCell;
    for (final e in cells) {
      if (!currentSafeMode.inLevel(e.rating.asSafeMode)) {
        continue;
      }

      if (prevCell != null) {
        if (prevCell.md5 == e.md5) {
          final prev = data[e.md5] ?? {};

          data[e.md5] = {...prev, (e.id, e.booru)};
        }
      }

      prevCell = e;
    }

    if (end) {
      return (collect(data), null);
    }

    return (const [], data);
  }

  late final state = GridSkeletonState<FavoritePostData>();

  late final ChainedFilterResourceSource<(int, Booru), FavoritePostData> filter;

  void disposeFavoriteBooruState() {
    settingsWatcher.cancel();
    filter.destroy();

    searchTextController.dispose();

    state.dispose();
  }

  void initFavoriteBooruState() {
    filter = ChainedFilterResourceSource(
      favoritePosts,
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.same => sameFavorites(
              cells,
              data,
              end,
              _collector,
              state.settings.safeMode,
            ),
          FilteringMode.tag => (
              searchTextController.text.isEmpty
                  ? cells.where(
                      (e) =>
                          state.settings.safeMode.inLevel(e.rating.asSafeMode),
                    )
                  : cells.where(
                      (e) =>
                          e.tags.contains(searchTextController.text) &&
                          state.settings.safeMode.inLevel(e.rating.asSafeMode),
                    ),
              data
            ),
          FilteringMode.gif => (
              cells.where(
                (element) =>
                    element.type == PostContentType.gif &&
                    state.settings.safeMode.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode.video => (
              cells.where(
                (element) =>
                    element.type == PostContentType.video &&
                    state.settings.safeMode.inLevel(element.rating.asSafeMode),
              ),
              data
            ),
          FilteringMode() => (
              cells.where(
                (e) => state.settings.safeMode.inLevel(e.rating.asSafeMode),
              ),
              data
            )
        };
      },
      ListStorage(reverse: true),
      prefilter: () {
        MiscSettingsService.db()
            .current
            .copy(favoritesPageMode: filter.filteringMode)
            .save();
      },
      allowedFilteringModes: const {
        FilteringMode.tag,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.same,
      },
      allowedSortingModes: const {},
      initialFilteringMode: MiscSettingsService.db().current.favoritesPageMode,
      initialSortingMode: SortingMode.none,
    );

    filter.clearRefresh();

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;
      filter.clearRefresh();
    });

    filter.clearRefresh();
  }

  void download(int i) => filter
      .forIdxUnsafe(i)
      .download(DownloadManager.of(context), PostTags.fromContext(context));

  List<GridAction<FavoritePostData>> gridActions() {
    return [
      booru_actions.download(context, state.settings.selectedBooru),
      booru_actions.favorites(
        context,
        favoritePosts,
        showDeleteSnackbar: true,
      ),
    ];
  }
}