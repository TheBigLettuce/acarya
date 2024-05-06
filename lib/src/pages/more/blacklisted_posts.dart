// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/grid_settings_base.dart";
import "package:gallery/src/db/services/impl/isar/schemas/grid_settings/booru.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/pages/more/blacklisted_page.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class BlacklistedPostsPage extends StatefulWidget {
  const BlacklistedPostsPage({
    super.key,
    required this.generateGlue,
    required this.conroller,
  });
  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;
  final ScrollController conroller;

  @override
  State<BlacklistedPostsPage> createState() => BlacklistedPostsPageState();
}

class BlacklistedPostsPageState extends State<BlacklistedPostsPage> {
  late final state = GridSkeletonRefreshingState<HiddenBooruPost>(
    initalCellCount: list.length,
    clearRefresh: SynchronousGridRefresh(() {
      list = HiddenBooruPost.getAll();

      return list.length;
    }),
  );
  List<HiddenBooruPost> list = <HiddenBooruPost>[];

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  GridSettingsBase _gridSettingsBase() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.one,
        columns: GridColumn.two,
        layoutType: GridLayoutType.list,
        hideName: false,
      );

  @override
  Widget build(BuildContext context) {
    return GlueProvider(
      generate: widget.generateGlue,
      child: GridFrame<HiddenBooruPost>(
        key: state.gridKey,
        getCell: (i) => list[i],
        overrideController: widget.conroller,
        layout: _ListLayout(
          HideBlacklistedImagesNotifier.of(context),
          _gridSettingsBase,
        ),
        functionality: GridFunctionality(
          selectionGlue: widget.generateGlue(),
          refreshingStatus: state.refreshingStatus,
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          showAppBar: false,
          asSliver: true,
          actions: [
            GridAction(
              Icons.photo,
              (selected) {
                HiddenBooruPost.removeAll(
                  selected
                      .cast<HiddenBooruPost>()
                      .map((e) => (e.postId, e.booru))
                      .toList(),
                );

                list = HiddenBooruPost.getAll();

                state.refreshingStatus.mutation.cellCount = list.length;
              },
              true,
            ),
          ],
          keybindsDescription:
              AppLocalizations.of(context)!.blacklistedPostsPageName,
          gridSeed: state.gridSeed,
        ),
      ),
    );
  }
}

class _ListLayout implements GridLayoutBehaviour {
  const _ListLayout(this.hideThumbnails, this.fnc);

  final bool hideThumbnails;
  final GridSettingsBase Function() fnc;

  @override
  GridSettingsBase Function() get defaultSettings => fnc;

  @override
  GridLayouter<T> makeFor<T extends CellBase>(GridSettingsBase settings) {
    return ListLayout<T>(hideThumbnails: hideThumbnails);
  }
}
