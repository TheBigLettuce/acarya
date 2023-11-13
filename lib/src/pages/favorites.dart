// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/widgets/grid/actions/favorites.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/interfaces/contentable.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/widgets/grid/callback_grid_shell.dart';
import 'package:gallery/src/widgets/grid/data_loaders/cell_loader.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:gallery/src/widgets/grid/data_loaders/read_only_loader.dart';
import 'package:gallery/src/widgets/grid/app_bar/grid_app_bar.dart';
import 'package:gallery/src/widgets/grid/grid_metadata.dart';
import 'package:gallery/src/widgets/grid/layouts/grid/grid.dart';
import 'package:gallery/src/widgets/grid/notifiers/notifier_registry_holder.dart';
import 'package:gallery/src/widgets/grid/segments.dart';
import 'package:gallery/src/widgets/notifiers/notifier_registry.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/linear_isar_loader.dart';
import '../interfaces/filtering/filtering_mode.dart';
import '../interfaces/filtering/sorting_mode.dart';
import '../widgets/grid/actions/booru_grid.dart';
import '../db/post_tags.dart';
import '../db/schemas/download_file.dart';
import '../db/schemas/settings.dart';
import '../widgets/grid/grid_action.dart';
import '../widgets/grid/search_and_focus.dart';
import '../widgets/grid/selection_glue.dart';
import '../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../widgets/skeletons/grid_skeleton.dart';
import 'booru/grid_settings_button.dart';

class FavoritesPage extends StatefulWidget {
  final void Function(bool) procPop;
  final SelectionGlue<FavoriteBooru> glue;

  const FavoritesPage({super.key, required this.procPop, required this.glue});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
// with SearchFilterGrid<FavoriteBooru>
{
  final booru = BooruAPI.fromSettings();
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  Map<String, int>? segments;

  bool segmented = false;

  // late final loader = LinearIsarLoader<FavoriteBooru>(
  //     FavoriteBooruSchema, Dbs.g.main, (offset, limit, s, sort, mode) {
  //   if (mode == FilteringMode.group) {
  //     if (s.isEmpty) {
  //       return Dbs.g.main.favoriteBoorus
  //           .where()
  //           .sortByGroupDesc()
  //           .thenByCreatedAtDesc()
  //           .offset(offset)
  //           .limit(limit)
  //           .findAllSync();
  //     }

  //     return Dbs.g.main.favoriteBoorus
  //         .filter()
  //         .groupContains(s)
  //         .sortByGroupDesc()
  //         .thenByCreatedAtDesc()
  //         .offset(offset)
  //         .limit(limit)
  //         .findAllSync();
  //   } else if (mode == FilteringMode.same) {
  //     return Dbs.g.main.favoriteBoorus
  //         .filter()
  //         .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
  //         .sortByMd5()
  //         .thenByCreatedAtDesc()
  //         .offset(offset)
  //         .limit(limit)
  //         .findAllSync();
  //   }

  //   return Dbs.g.main.favoriteBoorus
  //       .filter()
  //       .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
  //       .sortByCreatedAtDesc()
  //       .offset(offset)
  //       .limit(limit)
  //       .findAllSync();
  // })
  //   ..filter.passFilter = (cells, data, end) {
  //     final filterMode = currentFilteringMode();

  //     if (filterMode == FilteringMode.group) {
  //       segments = segments ?? {};

  //       for (final e in cells) {
  //         segments![e.group ?? "Ungrouped"] =
  //             (segments![e.group ?? "Ungrouped"] ?? 0) + 1;
  //       }
  //     } else {
  //       segments = null;
  //     }

  //     return switch (filterMode) {
  //       FilteringMode.same => _same(cells, data, end),
  //       FilteringMode.ungrouped => (
  //           cells.where(
  //               (element) => element.group == null || element.group!.isEmpty),
  //           data
  //         ),
  //       FilteringMode.gif => (
  //           cells.where((element) => element.fileDisplay() is NetGif),
  //           data
  //         ),
  //       FilteringMode.video => (
  //           cells.where((element) => element.fileDisplay() is NetVideo),
  //           data
  //         ),
  //       FilteringMode() => (cells, data)
  //     };
  //   };

  // (Iterable<FavoriteBooru>, dynamic) _same(
  //     Iterable<FavoriteBooru> cells, Map<String, Set<String>>? data, bool end) {
  //   data = data ?? {};

  //   FavoriteBooru? prevCell;
  //   for (final e in cells) {
  //     if (prevCell != null) {
  //       if (prevCell.md5 == e.md5) {
  //         final prev = data[e.md5] ?? {prevCell.fileUrl};

  //         data[e.md5] = {...prev, e.fileUrl};
  //       }
  //     }

  //     prevCell = e;
  //   }

  //   if (end) {
  //     return (
  //       () sync* {
  //         for (final ids in data!.values) {
  //           for (final i in ids) {
  //             final f = loader.instance.favoriteBoorus.getByFileUrlSync(i)!;
  //             f.isarId = null;
  //             yield f;
  //           }
  //         }
  //       }(),
  //       null
  //     );
  //   }

  //   return ([], data);
  // }

  // late final state = GridSkeletonStateFilter<FavoriteBooru>(
  //   filter: loader.filter,
  //   unsetFilteringModeOnReset: false,
  //   hook: (selected) {
  //     segments = null;
  //     if (selected == FilteringMode.group) {
  //       segmented = true;
  //       setState(() {});
  //     } else {
  //       segmented = false;
  //       setState(() {});
  //     }

  //     Settings.fromDb().copy(favoritesPageMode: selected).save();

  //     return SortingMode.none;
  //   },
  //   defaultMode: FilteringMode.tag,
  //   filteringModes: {
  //     FilteringMode.tag,
  //     FilteringMode.group,
  //     FilteringMode.ungrouped,
  //     FilteringMode.gif,
  //     FilteringMode.video,
  //     FilteringMode.same,
  //   },
  //   transform: (FavoriteBooru cell, SortingMode sort) {
  //     return cell;
  //   },
  // );

  final state = GridSkeletonState<FavoriteBooru>();

  void _download(FavoriteBooru cell) {
    PostTags.g.addTagsPost(cell.filename(), cell.tags, true);

    Downloader.g.add(
        DownloadFile.d(
            url: cell.fileDownloadUrl(),
            site: booru.booru.url,
            name: cell.filename(),
            thumbUrl: cell.previewUrl),
        state.settings);
  }

  final loader = ReadOnlyDataLoader<FavoriteBooru, int, String>(
    Dbs.g.main,
    (db, idx) =>
        db.favoriteBoorus.where().sortByPostIdDesc().findFirst(offset: idx),
    makeTransformer: (instance) => CellDataTransformer<FavoriteBooru, int>(
        instance,
        (instance, cell) => cell,
        (instance) => 0,
        FilteringMode.noFilter,
        SortingMode.none),
  );

  @override
  void initState() {
    super.initState();
    // searchHook(state);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      // setFilteringMode(state.settings.favoritesPageMode);
      // setLocalTagCompleteF((string) {
      //   final result = Dbs.g.main.localTagDictionarys
      //       .filter()
      //       .tagContains(string)
      //       .sortByFrequencyDesc()
      //       .limit(10)
      //       .findAllSync();

      //   return Future.value(result.map((e) => e.tag).toList());
      // });

      // performSearch("");

      setState(() {});
    });

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      // performSearch(searchTextController.text);
    });
  }

  late final notifiers = NotifierRegistry.genericNotifiers<FavoriteBooru>(
    context,
    widget.glue,
    GridMetadata(
      gridActions: [BooruGridActions.download(context), _groupButton(context)],
      onPressed: GridMetadata.launchImageView<FavoriteBooru>,
      aspectRatio: state.settings.favorites.aspectRatio,
      columns: state.settings.favorites.columns,
      hideAlias: true,
      isList: state.settings.favorites.listView,
    ),
    NoteBooru.interface(setState),
  );

  GridAction<FavoriteBooru> _groupButton(BuildContext context) {
    return FavoritesActions.addToGroup(context, (selected) {
      final g = selected.first.group;
      for (final e in selected.skip(1)) {
        if (g != e.group) {
          return null;
        }
      }

      return g;
    }, (selected, value) {
      Dbs.g.main.write((i) => i.favoriteBoorus
          .putAll(selected.map((e) => e.withGroup(value)).toList()));

      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    state.dispose();
    loader.dispose();
    // disposeSearch();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotifierRegistryHolder(
      l: notifiers,
      child: GridSkeleton<FavoriteBooru>(
          state,
          CallbackGridShell<FavoriteBooru>(
              loader: loader,
              appBar: GridAppBar.basic(
                actions: [
                  gridSettingsButton(state.settings.favorites,
                      selectHideName: null,
                      selectRatio: (ratio) => state.settings
                          .copy(
                              favorites: state.settings.favorites
                                  .copy(aspectRatio: ratio))
                          .save(),
                      selectListView: null,
                      selectGridColumn: (columns) => state.settings
                          .copy(
                              favorites: state.settings.favorites
                                  .copy(columns: columns))
                          .save())
                ],
              ),
              keybinds: const {},
              // showCount: true,
              // systemNavigationInsets: EdgeInsets.only(
              //     bottom: MediaQuery.systemGestureInsetsOf(context).bottom +
              //         (Scaffold.of(context).widget.bottomNavigationBar !=
              //                     null &&
              //                 !widget.glue.keyboardVisible()
              //             ? 80
              //             : 0)),
              // hasReachedEnd: () => true,
              // download: _download,
              // addFabPadding:
              //     Scaffold.of(context).widget.bottomNavigationBar == null,
              mainFocus: state.mainFocus,

              // refresh: () => Future.value(loader.count()),

              child: GridLayout<FavoriteBooru>(download: null)
              //  GridLayout<FavoriteBooru>(
              //   aspectRatio: state.settings.favorites.aspectRatio,
              //   columns: state.settings.favorites.columns,
              //   // getOriginalCell: loader.getCell,
              //   segments: segmented
              //       ? Segments(
              //           "Ungrouped", // TODO: change
              //           hidePinnedIcon: true,
              //           prebuiltSegments: segments,
              //         )
              //       : null,
              // search: SearchAndFocus(
              //     searchWidget(context,
              //         hint: AppLocalizations.of(context)!
              //             .favoritesLabel
              //             .toLowerCase()),
              //     searchFocus),
              // ),
              ),
          canPop: false, overrideOnPop: (pop, hideAppBar) {
        // if (searchTextController.text.isNotEmpty) {
        //   resetSearch();
        //   return;
        // }
        // if (widget.glue.isOpen()) {
        //   state.gridKey.currentState?.selection.reset();
        //   return;
        // }

        if (hideAppBar()) {
          setState(() {});
          return;
        }

        widget.procPop(pop);
      }),
    );
  }
}
