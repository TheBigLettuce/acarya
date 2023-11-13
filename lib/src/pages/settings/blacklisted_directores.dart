// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid/callback_grid_shell.dart';
import 'package:gallery/src/widgets/grid/data_loaders/dummy_loader.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:gallery/src/widgets/grid/data_loaders/read_only_loader.dart';
import 'package:gallery/src/widgets/grid/grid_action.dart';
import 'package:gallery/src/widgets/grid/app_bar/grid_app_bar.dart';
import 'package:gallery/src/widgets/grid/grid_metadata.dart';
import 'package:gallery/src/widgets/grid/layouts/list/list.dart';
import 'package:gallery/src/widgets/grid/notifiers/notifier_registry_holder.dart';
import 'package:gallery/src/widgets/grid/search_and_focus.dart';
import 'package:gallery/src/widgets/notifiers/notifier_registry.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/linear_isar_loader.dart';
import '../../widgets/grid/wrap_grid_page.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/grid_skeleton.dart';

class BlacklistedDirectories extends StatefulWidget {
  const BlacklistedDirectories({super.key});

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories>
// with SearchFilterGrid<BlacklistedDirectory>
{
  late final StreamSubscription blacklistedWatcher;
  late final state = GridSkeletonState<BlacklistedDirectory>();

  final loader = ReadOnlyDataLoader<BlacklistedDirectory, int, int>(
      Dbs.g.blacklisted,
      (db, idx) => db.blacklistedDirectorys.where().findFirst(offset: idx));

  @override
  void initState() {
    super.initState();
    // searchHook(state);

    blacklistedWatcher = Dbs.g.blacklisted.blacklistedDirectorys
        .watchLazy(fireImmediately: true)
        .listen((event) {
      // performSearch(searchTextController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    state.dispose();
    // disposeSearch();
    loader.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WrappedGridPage<BlacklistedDirectory>(
      scaffoldKey: state.scaffoldKey,
      child: NotifierRegistryHolder(
          l: NotifierRegistry.basicNotifiers<BlacklistedDirectory>(
              context,
              GridMetadata(
                gridActions: [
                  GridAction(
                    Icons.restore_page,
                    (selected) {
                      Dbs.g.blacklisted.write((i) {
                        return i.blacklistedDirectorys.deleteAll(
                            selected.map((e) => e.bucketId).toList());
                      });
                    },
                    true,
                  )
                ],
                aspectRatio: GridAspectRatio.one,
                columns: GridColumn.two,
                isList: true,
              )),
          child: GridSkeleton(
            state,
            CallbackGridShell<BlacklistedDirectory>(
              loader: DummyBackgroundLoader(),
              appBar: GridAppBar.basic(
                leading: const BackButton(),
                actions: [
                  IconButton(
                    onPressed: () {
                      Dbs.g.blacklisted
                          .write((i) => i.blacklistedDirectorys.clear());
                      // chooseGalleryPlug().notify(null);
                    },
                    icon: const Icon(Icons.delete),
                  )
                ],
              ),

              // addFabPadding: true,
              mainFocus: state.mainFocus,
              // unpressable: true,
              // showCount: true,

              // keybindsDescription: AppLocalizations.of(context)!
              // .blacklistedDirectoriesPageName,

              keybinds: const {},
              child: const ListLayout<BlacklistedDirectory>(

                  //   // search: SearchAndFocus(
                  //   //     searchWidget(
                  //   //       context,
                  //   //       hint: AppLocalizations.of(context)!
                  //   //           .blacklistedDirectoriesPageName
                  //   //           .toLowerCase(),
                  //   //     ),
                  //   //     searchFocus)
                  //   // ,
                  ),
            ),
            canPop: true,
            // !glue.isOpen() &&
            // state.gridKey.currentState?.showSearchBar != true,

            overrideOnPop: (pop, hideAppBar) {
              // if (glue.isOpen()) {
              //   state.gridKey.currentState?.selection.reset();
              //   return;
              // }

              if (hideAppBar()) {
                setState(() {});
                return;
              }
            },
          )),
    );
  }
}
