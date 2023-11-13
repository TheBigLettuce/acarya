// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/widgets/bookmark_button.dart';
import 'package:gallery/src/widgets/grid/app_bar/grid_app_bar_title.dart';
import 'package:gallery/src/widgets/grid/app_bar/search_grid.dart';
import 'package:gallery/src/widgets/grid/data_loaders/cell_loader.dart';
import 'package:gallery/src/widgets/grid/app_bar/grid_app_bar.dart';
import 'package:gallery/src/interfaces/background_data_loader/loader_keys.dart';
import 'package:gallery/src/widgets/grid/metadata/grid_metadata.dart';
import 'package:gallery/src/widgets/grid/layouts/grid.dart';
import 'package:gallery/src/widgets/grid/layouts/list.dart';
import 'package:gallery/src/widgets/grid/metadata/search_and_focus.dart';
import 'package:gallery/src/widgets/notifiers/is_search_showed.dart';
import 'package:gallery/src/widgets/notifiers/notifier_registry.dart';
import 'package:gallery/src/widgets/notifiers/state_restoration.dart';
import 'package:isar/isar.dart';
import 'package:gallery/src/widgets/grid/callback_grid_shell.dart';

import '../../widgets/grid/actions/booru_grid.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/post.dart';
import '../../db/schemas/settings.dart';
import '../../widgets/grid/selection/selection_glue.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/skeletons/grid_skeleton.dart';
import '../../widgets/grid_settings_button.dart';

class MainBooruGrid extends StatefulWidget {
  final Isar mainGrid;
  final void Function(bool) procPop;
  final SelectionGlue<Post> glue;

  const MainBooruGrid(
      {super.key,
      required this.mainGrid,
      required this.glue,
      required this.procPop});

  static Widget bookmarkButton(BuildContext context, GridSkeletonState state,
      SelectionGlue glue, void Function() f) {
    return IconButton(
        onPressed: () {
          f();
          ScaffoldMessenger.of(state.scaffoldKey.currentContext!)
              .showSnackBar(const SnackBar(
                  content: Text(
            "Bookmarked", // TODO: change
          )));
          glue.close();
          // state.gridKey.currentState?.selection.selected.clear();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.bookmark_add));
  }

  static PopupMenuButton gridButton(Settings settings,
      {void Function(SafeMode?)? selectSafeMode, SafeMode? currentSafeMode}) {
    return gridSettingsButton(
      settings.booru,
      selectSafeMode: selectSafeMode,
      selectHideName: null,
      safeMode: currentSafeMode ?? settings.safeMode,
      selectGridColumn: (columns) =>
          settings.copy(booru: settings.booru.copy(columns: columns)).save(),
      selectListView: (listView) =>
          settings.copy(booru: settings.booru.copy(listView: listView)).save(),
      selectRatio: (ratio) =>
          settings.copy(booru: settings.booru.copy(aspectRatio: ratio)).save(),
    );
  }

  @override
  State<MainBooruGrid> createState() => _MainBooruGridState();
}

class _MainBooruGridState extends State<MainBooruGrid> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  late final StateRestoration restore;

  late final loader =
      BackgroundCellLoader<Post, String>.cached(kMainGridLoaderKey);

  late final List<InheritedWidget Function(Widget)> registrer;

  final state = GridSkeletonState<Post>();

  @override
  void initState() {
    super.initState();

    // main grid safe mode only from Settings
    restore = StateRestoration(widget.mainGrid,
        state.settings.selectedBooru.string, state.settings.safeMode);
    // api = BooruAPI.fromSettings(page: restore.copy.page);

    // tagManager = TagManager(restore, (fire, f) {
    //   return widget.mainGrid.tags
    //       .watchLazy(fireImmediately: fire)
    //       .listen((event) {
    //     f();
    //   });
    // });

    // api.page(0, "", tagManager.excluded).then((value) {
    //   loader.send(value.$1);
    // });

    // searchHook(SearchLaunchGridData(
    //     mainFocus: state.mainFocus,
    //     searchText: "",
    //     addItems: null,
    //     restorable: true));

    // if (api.wouldBecomeStale &&
    //     state.settings.autoRefresh &&
    //     state.settings.autoRefreshMicroseconds != 0 &&
    //     restore.copy.time.isBefore(DateTime.now()
    //         .subtract(state.settings.autoRefreshMicroseconds.microseconds))) {
    //   // widget.mainGrid.writeTxnSync(() => widget.mainGrid.posts.clearSync());
    //   // restore.updateTime();
    // }

    registrer = [
      (child) => StateRestorationProvider(
            state: restore,
            child: IsSearchShowingHolder(
              child: child,
            ),
          ),
      ...NotifierRegistry.genericNotifiers<Post>(
        context,
        widget.glue,
        GridMetadata(
          isList: false,
          aspectRatio: state.settings.booru.aspectRatio,
          columns: state.settings.booru.columns,
          onPressed: GridMetadata.launchImageView<Post>,
          hideAlias: false,
          gridActions: [
            BooruGridActions.download(context),
            BooruGridActions.favorites(context)
          ],
        ),
        NoteBooru.interface(setState),
      )
    ];

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      // state.gridKey.currentState?.imageViewKey.currentState?.setState(() {});
      setState(() {});
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotifierRegistryHolder(
      l: registrer,
      child: GridSkeleton(
        state,
        CallbackGridShell<Post>(
          loader: loader,
          appBar: GridAppBar.basic(
            actions: [
              const BookmarkButton(),
              MainBooruGrid.gridButton(state.settings)
            ],
            title: GridAppBarTitle(
              searchWidget: SearchAndFocus(
                SearchLaunchGrid1(
                    booru: state.settings.selectedBooru,
                    complF: (s) => Future.value([])),
                state.mainFocus,
              ),
              child: const SearchCharacterTitle(),
            ),
          ),
          keybinds: const {},
          mainFocus: state.mainFocus,
          child: state.settings.booru.listView
              ? const ListLayout<Post>()
              : const GridLayout<Post>(),
        ),
        canPop: true,
        // !widget.glue.isOpen() &&
        //     state.gridKey.currentState?.showSearchBar != true,
        overrideOnPop: (pop, hideAppBar) {
          // if (widget.glue.isOpen()) {
          //   state.gridKey.currentState?.selection.reset();
          //   return;
          // }

          if (hideAppBar()) {
            setState(() {});
            return;
          }

          widget.procPop(pop);
        },
      ),
    );
  }
}

//   Future<void> _download(int i) async {
//   final p = widget.mainGrid.posts.getSync(i + 1);
//   if (p == null) {
//     return Future.value();
//   }

//   PostTags.g.addTagsPost(p.filename(), p.tags, true);

//   return Downloader.g.add(
//       DownloadFile.d(
//           url: p.fileDownloadUrl(),
//           site: api.booru.url,
//           name: p.filename(),
//           thumbUrl: p.previewUrl),
//       state.settings);
// }

// Future<int> _addLast() async {
//   if (reachedEnd) {
//     return widget.mainGrid.posts.countSync();
//   }
//   final p = widget.mainGrid.posts.getSync(widget.mainGrid.posts.countSync());
//   if (p == null) {
//     return widget.mainGrid.posts.countSync();
//   }

//   try {
//     final list = await api.fromPost(
//         currentSkipped != null && currentSkipped! < p.id
//             ? currentSkipped!
//             : p.id,
//         "",
//         tagManager.excluded);
//     if (list.$1.isEmpty && currentSkipped == null) {
//       reachedEnd = true;
//     } else {
//       currentSkipped = list.$2;
//       final oldCount = widget.mainGrid.posts.countSync();
//       widget.mainGrid.writeTxnSync(
//           () => widget.mainGrid.posts.putAllByFileUrlSync(list.$1));
//       restore.updateTime();
//       if (widget.mainGrid.posts.countSync() - oldCount < 3) {
//         return await _addLast();
//       }
//     }
//   } catch (e, trace) {
//     log("_addLast on grid ${state.settings.selectedBooru.string}",
//         level: Level.WARNING.value, error: e, stackTrace: trace);
//   }

//   return widget.mainGrid.posts.count();
// }

// systemNavigationInsets: EdgeInsets.only(
//     bottom: MediaQuery.of(context).systemGestureInsets.bottom +
//         (Scaffold.of(context).widget.bottomNavigationBar !=
//                     null &&
//                 !widget.glue.keyboardVisible()
//             ? 80
//             : 0)),
// selectionGlue: widget.glue,

// inlineMenuButtonItems: true,
// addFabPadding:
//     Scaffold.of(context).widget.bottomNavigationBar == null,
// menuButtonItems: [
//   const BookmarkButton(),
//   MainBooruGrid.gridButton(state.settings)
// ],
// addIconsImage: (post) => [
//   BooruGridActions.favorites(context, post),
//   BooruGridActions.download(context, api)
// ],
// onExitImageView: () => restore.removeScrollTagsSelectedPost(),
// description: GridDescription([
//   BooruGridActions.download(context, api),
//   BooruGridActions.favorites(context, null,
//       showDeleteSnackbar: true)
// ],
//     keybindsDescription:
//         AppLocalizations.of(context)!.booruGridPageName,
//     layout: state.settings.booru.listView
//         ? const ListLayout()
//         : GridLayout(state.settings.booru.columns,
//             state.settings.booru.aspectRatio)),
// hasReachedEnd: () => reachedEnd,

// scaffoldKey: state.scaffoldKey,
// noteInterface: NoteBooru.interface(setState),
// onError: (error) {
//   return OutlinedButton(
//     onPressed: () {
//       launchUrl(Uri.https(api.booru.url),
//           mode: LaunchMode.externalApplication);
//     },
//     child: Text(AppLocalizations.of(context)!.openInBrowser),
//   );
// },
// getCell: (i) => widget.mainGrid.posts.getSync(i + 1)!,
// loadNext: _addLast,
// refresh: _clearAndRefresh,
// hideAlias: true,
// download: _download,
// updateScrollPosition: (pos, {infoPos, selectedCell}) =>
//     restore.updateScrollPosition(pos,
//         infoPos: infoPos,
//         selectedCell: selectedCell,
//         page: api.currentPage),
// initalScrollPosition: restore.copy.scrollPositionGrid,
// initalCellCount: widget.mainGrid.posts.countSync(),
// beforeImageViewRestore: () {
//   final last = restore.last();
//   if (last != null) {
//     WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
//       Navigator.push(context, MaterialPageRoute(
//         builder: (context) {
//           return SecondaryBooruGrid(
//             restore: last,
//             noRestoreOnBack: false,
//             api: BooruAPI.fromEnum(api.booru,
//                 page: last.copy.page),
//             tagManager: tagManager,
//             instance: DbsOpen.secondaryGridName(last.copy.name),
//           );
//         },
//       ));
//     });
//   }
// },
// pageViewScrollingOffset: restore.copy.scrollPositionTags,
// initalCell: restore.copy.selectedPost,


