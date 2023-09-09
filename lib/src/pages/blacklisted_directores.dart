// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BlacklistedDirectories extends StatefulWidget {
  const BlacklistedDirectories({super.key});

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories>
    with SearchFilterGrid<BlacklistedDirectory> {
  late final StreamSubscription blacklistedWatcher;
  final loader = LinearIsarLoader<BlacklistedDirectory>(
      BlacklistedDirectorySchema,
      blacklistedDirIsar(),
      (offset, limit, s, sort, mode) => blacklistedDirIsar()
          .blacklistedDirectorys
          .filter()
          .nameContains(s, caseSensitive: false)
          .offset(offset)
          .limit(limit)
          .findAllSync());
  late final state = GridSkeletonStateFilter<BlacklistedDirectory>(
    filter: loader.filter,
    index: kSettingsDrawerIndex,
    transform: (cell, sort) => cell,
  );

  @override
  void initState() {
    super.initState();
    searchHook(state);
    // loader.init((instance) {});

    blacklistedWatcher = blacklistedDirIsar()
        .blacklistedDirectorys
        .watchLazy(fireImmediately: true)
        .listen((event) {
      performSearch(searchTextController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    state.dispose();
    disposeSearch();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton(
        context,
        state,
        CallbackGrid<BlacklistedDirectory>(
            key: state.gridKey,
            getCell: loader.getCell,
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
            hasReachedEnd: () => true,
            aspectRatio: 1,
            immutable: false,
            searchWidget: SearchAndFocus(
                searchWidget(
                  context,
                  hint: AppLocalizations.of(context)!
                      .blacklistedDirectoriesPageName
                      .toLowerCase(),
                ),
                searchFocus),
            mainFocus: state.mainFocus,
            unpressable: true,
            hideShowFab: ({required bool fab, required bool foreground}) =>
                state.updateFab(setState, fab: fab, foreground: foreground),
            menuButtonItems: [
              IconButton(
                  onPressed: () {
                    blacklistedDirIsar().writeTxnSync(() =>
                        blacklistedDirIsar().blacklistedDirectorys.clearSync());
                    GalleryImpl.instance().notify(null);
                  },
                  icon: const Icon(Icons.delete))
            ],
            refresh: () => Future.value(loader.count()),
            description: GridDescription(
                kSettingsDrawerIndex,
                [
                  GridBottomSheetAction(Icons.restore_page, (selected) {
                    blacklistedDirIsar().writeTxnSync(() {
                      return blacklistedDirIsar()
                          .blacklistedDirectorys
                          .deleteAllByBucketIdSync(
                              selected.map((e) => e.bucketId).toList());
                    });
                  },
                      true,
                      const GridBottomSheetActionExplanation(
                        label: "Unblacklist", // TODO: change
                        body:
                            "Unblacklist selected directories.", // TODO: change
                      ))
                ],
                GridColumn.two,
                keybindsDescription: AppLocalizations.of(context)!
                    .blacklistedDirectoriesPageName,
                listView: true)),
        popSenitel: false);
  }
}
