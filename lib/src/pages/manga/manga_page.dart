// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';
import 'package:gallery/src/db/schemas/manga/compact_manga_data.dart';
import 'package:gallery/src/db/schemas/manga/pinned_manga.dart';
import 'package:gallery/src/db/schemas/manga/read_manga_chapter.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/net/manga/manga_dex.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/manga/manga_info_page.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_column.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_fab_type.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_on_cell_press_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';
import 'package:gallery/src/widgets/grid_frame/parts/segment_label.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MangaPage extends StatefulWidget {
  final void Function(bool) procPop;
  final EdgeInsets? viewPadding;
  final bool wrapGridPage;

  const MangaPage({
    super.key,
    required this.procPop,
    this.wrapGridPage = false,
    required this.viewPadding,
  });

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  late final StreamSubscription<void> watcher;

  final data = <CompactMangaData>[];
  final state = GridSkeletonState<CompactMangaDataBase>();

  final dio = Dio();
  late final api = MangaDex(dio);

  final GlobalKey<_PinnedMangaWidgetState> _pinnedKey = GlobalKey();

  bool dirty = false;

  bool inInner = false;

  @override
  void initState() {
    super.initState();

    watcher = ReadMangaChapter.watch((_) {
      if (inInner) {
        dirty = true;
      } else {
        _refreshGrid();
      }
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    dio.close();

    super.dispose();
  }

  Future<int> refresh() async {
    data.clear();

    final l = ReadMangaChapter.lastRead(50);
    for (final e in l) {
      final d = CompactMangaData.get(e.siteMangaId, api.site);
      if (d != null) {
        data.add(d);
      }
    }

    return data.length;
  }

  void _startReading(int i) {
    final c = ReadMangaChapter.firstForId(data[i].mangaId);
    assert(c != null);
    if (c == null) {
      return;
    }

    final e = data[i];

    inInner = true;

    ReadMangaChapter.launchReader(
      context,
      Theme.of(context).colorScheme.background,
      mangaTitle: e.title,
      mangaId: MangaStringId(e.mangaId),
      chapterId: c.chapterId,
      onNextPage: (p, cell) {},
      reloadChapters: () {},
      api: api,
      addNextChapterButton: true,
    ).then((value) {
      _procReload();
    });
  }

  void _procReload() {
    inInner = false;

    if (dirty) {
      _refreshGrid();
    }
  }

  void _refreshGrid() {
    final mutation = state.gridKey.currentState?.mutation;

    mutation?.cellCount = 0;
    mutation?.isRefreshing = true;
    refresh().whenComplete(() {
      mutation?.cellCount = data.length;
      mutation?.isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = widget.viewPadding ?? MediaQuery.viewPaddingOf(context);

    final child = GridSkeleton<CompactMangaDataBase>(
      state,
      (context) => GridFrame<CompactMangaDataBase>(
        key: state.gridKey,
        layout: _ReadingLayout(
          startReading: _startReading,
          pinnedMangaKey: _pinnedKey,
        ),
        refreshingStatus: state.refreshingStatus,
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
        functionality: GridFunctionality(
            onPressed: OverrideGridOnCellPressBehaviour(
              onPressed: (context, idx, overrideCell) {
                final cell = overrideCell as CompactMangaDataBase? ??
                    CellProvider.getOf<CompactMangaDataBase>(context, idx);
                inInner = true;

                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(
                  builder: (context) {
                    return MangaInfoPage(
                      id: MangaStringId(cell.mangaId),
                      api: api,
                    );
                  },
                )).then((value) {
                  _procReload();
                });
              },
            ),
            selectionGlue: GlueProvider.of(context),
            refresh: AsyncGridRefresh(
              refresh,
              pullToRefresh: false,
            ),
            fab: OverrideGridFab(
              (scrollController) {
                return ReadingFab(
                  viewPadding: viewPadding,
                  api: api,
                  controller: scrollController,
                );
              },
            )),
        getCell: (i) => data[i],
        initalScrollPosition: 0,
        systemNavigationInsets: viewPadding,
        mainFocus: state.mainFocus,
        description: GridDescription(
          risingAnimation: !state.settings.buddhaMode,
          actions: const [],
          appBarSnap: !state.settings.buddhaMode,
          ignoreEmptyWidgetOnNoContent: true,
          ignoreSwipeSelectGesture: true,
          showAppBar: state.settings.buddhaMode,
          keybindsDescription: AppLocalizations.of(context)!.mangaPage,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: state.settings.buddhaMode,
      secondarySelectionHide: () {
        _pinnedKey.currentState?.selection.reset();
      },
      overrideOnPop: widget.procPop,
    );

    return SafeArea(
      bottom: false,
      child: widget.wrapGridPage
          ? WrapGridPage<CompactMangaDataBase>(
              scaffoldKey: state.scaffoldKey,
              child: child,
            )
          : child,
    );
  }
}

class ReadingFab extends StatefulWidget {
  final MangaAPI api;
  final EdgeInsets viewPadding;
  final ScrollController controller;

  const ReadingFab({
    super.key,
    required this.api,
    required this.viewPadding,
    required this.controller,
  });

  @override
  State<ReadingFab> createState() => _ReadingFabState();
}

class _ReadingFabState extends State<ReadingFab>
    with SingleTickerProviderStateMixin {
  SelectionGlue<J> _generateGlue<J extends Cell>() {
    return GlueProvider.generateOf<CompactMangaDataBase, J>(context);
  }

  late final AnimationController animation;

  bool extended = true;

  void _listener() {
    if (widget.controller.offset == 0 && !extended) {
      animation.reverse().then((value) => setState(() {
            extended = true;
          }));
    } else if (widget.controller.offset > 0 && extended) {
      animation.forward().then((value) => setState(() {
            extended = false;
          }));
    }
  }

  @override
  void initState() {
    super.initState();

    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final pos = widget.controller.positions.toList();
      if (pos.isEmpty) {
        return;
      }

      pos.first.addListener(_listener);
    });
  }

  @override
  void dispose() {
    animation.dispose();

    final pos = widget.controller.positions.toList();
    if (pos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        pos.first.removeListener(_listener);
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      isExtended: extended,
      shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0)))
          .lerpTo(
        const CircleBorder(),
        Easing.standard.transform(animation.value),
      ),
      onPressed: () {
        SearchAnimePage.launchMangaApi(
          context,
          widget.api,
          search: "",
          viewInsets: widget.viewPadding,
          generateGlue: _generateGlue,
        );
      },
      label: Text(AppLocalizations.of(context)!.searchHint),
      icon: const Icon(Icons.search),
    );
  }
}

class _ReadingLayout
    implements GridLayouter<CompactMangaDataBase>, GridLayoutBehaviour {
  const _ReadingLayout({
    required this.startReading,
    required this.pinnedMangaKey,
  });

  final void Function(int idx) startReading;
  final GlobalKey<_PinnedMangaWidgetState> pinnedMangaKey;

  static GridSettingsBase _defaultSettings() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.oneTwo,
        columns: GridColumn.three,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  final GridSettingsBase Function() defaultSettings = _defaultSettings;

  @override
  GridLayouter<T> makeFor<T extends Cell>(GridSettingsBase settings) {
    return this as GridLayouter<T>;
  }

  @override
  List<Widget> call(BuildContext context, GridSettingsBase settings,
      GridFrameState<CompactMangaDataBase> state) {
    void onPressed(CompactMangaDataBase e, int idx) {
      state.widget.functionality.onPressed.launch(context, idx, state);
    }

    void onLongPressed(CompactMangaDataBase e, int idx) {
      startReading(idx);
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: SliverToBoxAdapter(
          child: MediumSegmentLabel(
            AppLocalizations.of(context)!.mangaReadingLabel,
            trailingWidget: TextButton(
              onPressed:
                  state.mutation.cellCount == 0 ? null : () => startReading(0),
              child: Text(AppLocalizations.of(context)!.mangaContinueReading),
            ),
          ),
        ),
      ),
      if (state.mutation.cellCount == 0)
        SliverToBoxAdapter(
          child: EmptyWidget(
            gridSeed: state.widget.description.gridSeed,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: (MediaQuery.sizeOf(context).shortestSide /
                  settings.columns.number),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.mutation.cellCount,
                itemBuilder: (context, index) {
                  final cell = state.widget.getCell(index);

                  return SizedBox(
                    width: (MediaQuery.sizeOf(context).shortestSide /
                            settings.columns.number) *
                        settings.aspectRatio.value,
                    child: ImportantCard(
                      cell: cell,
                      idx: index,
                      onLongPressed: onLongPressed,
                      onPressed: onPressed,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: SliverToBoxAdapter(
          child: MediumSegmentLabel(
            AppLocalizations.of(context)!.mangaPinnedLabel,
          ),
        ),
      ),
      _PinnedMangaWidget(
        key: pinnedMangaKey,
        controller: state.controller,
        onPress: (context, cell) {
          state.widget.functionality.onPressed
              .launch(context, -1, state, useCellInsteadIdx: cell);
        },
        glue:
            GlueProvider.generateOf<CompactMangaDataBase, PinnedManga>(context),
      )
    ];
  }

  @override
  bool get isList => false;
}

class _PinnedMangaWidget extends StatefulWidget {
  final SelectionGlue<PinnedManga> glue;
  final ScrollController controller;
  final void Function(BuildContext, PinnedManga) onPress;

  const _PinnedMangaWidget({
    super.key,
    required this.glue,
    required this.controller,
    required this.onPress,
  });

  @override
  State<_PinnedMangaWidget> createState() => _PinnedMangaWidgetState();
}

class _PinnedMangaWidgetState extends State<_PinnedMangaWidget> {
  late final StreamSubscription<void> watcher;
  final data = PinnedManga.getAll(-1);

  late final GridMutationInterface<PinnedManga> mutationInterface =
      DefaultMutationInterface(data.length);
  late final GridSelection<PinnedManga> selection = GridSelection(
    setState,
    [
      GridAction(Icons.push_pin_rounded, (selected) {
        PinnedManga.deleteAll(selected.map((e) => e.isarId!).toList());

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.mangaUnpinned),
          action: SnackBarAction(
              label: AppLocalizations.of(context)!.undoLabel,
              onPressed: () {
                PinnedManga.addAll(selected, true);
              }),
        ));
      }, true),
    ],
    widget.glue,
    () => widget.controller,
    noAppBar: true,
    ignoreSwipe: false,
  );

  @override
  void initState() {
    super.initState();

    watcher = PinnedManga.watch((_) {
      data.clear();
      data.addAll(PinnedManga.getAll(-1));

      mutationInterface.cellCount = data.length;
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();
    mutationInterface.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CellProvider(
      getCell: (i) => data[data.length - 1 - i],
      child: SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: data.isEmpty
            ? const SliverToBoxAdapter(
                child: EmptyWidget(gridSeed: 0),
              )
            : Builder(
                builder: (context) {
                  return GridLayout.blueprint<PinnedManga>(
                    context,
                    mutationInterface,
                    selection,
                    gridCell: (context, idx) {
                      final cell = data[data.length - 1 - idx];

                      return GridCell(
                        cell: cell,
                        indx: idx,
                        imageAlign: Alignment.topCenter,
                        alignTitleToTopLeft: true,
                        onPressed: (context) {
                          widget.onPress(context, cell);
                        },
                        onLongPress: () {
                          selection.selectOrUnselect(context, idx);
                        },
                        tight: false,
                        download: null,
                        isList: false,
                        hideAlias: false,
                      );
                    },
                    columns: GridColumn.three.number,
                    systemNavigationInsets: 0,
                    aspectRatio: GridAspectRatio.one.value,
                  );
                },
              ),
      ),
    );
  }
}
