// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../anime.dart';

class _WatchingTab extends StatefulWidget {
  final EdgeInsets viewInsets;
  final void Function() onDispose;
  final void Function(bool) procPop;

  const _WatchingTab(
    this.viewInsets, {
    required super.key,
    required this.procPop,
    required this.onDispose,
  });

  @override
  State<_WatchingTab> createState() => __WatchingTabState();
}

class __WatchingTabState extends State<_WatchingTab> {
  final state = GridSkeletonState<SavedAnimeEntry>();
  final List<SavedAnimeEntry> currentlyWatching =
      SavedAnimeEntry.currentlyWatching();
  final List<SavedAnimeEntry> backlog = SavedAnimeEntry.backlog();

  final List<SavedAnimeEntry> _backlogFilter = [];
  final List<SavedAnimeEntry> _watchingFilter = [];

  late final StreamSubscription<void> watcher;
  final gridSeed = math.Random().nextInt(948512342);

  bool upward = MiscSettings.current.animeWatchingOrderReversed;
  bool right = false;
  String _filteringValue = "";

  void filter(String value) {
    final m = state.gridKey.currentState?.mutation;
    if (m == null) {
      return;
    }
    value = value.trim();

    _filteringValue = value;

    final l = value.toLowerCase();

    _backlogFilter.clear();
    _watchingFilter.clear();

    if (value.isEmpty) {
      setState(() {});

      m.cellCount = backlog.length;

      return;
    }

    _backlogFilter.addAll(
        backlog.where((element) => element.title.toLowerCase().contains(l)));
    _watchingFilter.addAll(currentlyWatching
        .where((element) => element.title.toLowerCase().contains(l)));

    m.cellCount = _backlogFilter.length;
  }

  @override
  void initState() {
    super.initState();

    watcher = SavedAnimeEntry.watchAll((_) {
      final newB = SavedAnimeEntry.backlog();
      backlog.clear();
      backlog.addAll(newB);

      if (_filteringValue.isEmpty) {
        state.gridKey.currentState?.mutation.cellCount = newB.length;
      } else {
        filter(_filteringValue);
      }

      currentlyWatching.clear();
      currentlyWatching.addAll(SavedAnimeEntry.currentlyWatching());
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    state.dispose();

    widget.onDispose();

    super.dispose();
  }

  SavedAnimeEntry _getCell(int i) {
    if (_backlogFilter.isNotEmpty) {
      return _backlogFilter[upward ? _backlogFilter.length - 1 - i : i];
    }

    return backlog[upward ? backlog.length - 1 - i : i];
  }

  @override
  Widget build(BuildContext context) {
    return GridSkeleton<AnimeEntry>(
      state,
      (context) => GridFrame<SavedAnimeEntry>(
        key: state.gridKey,
        layout: _WatchingLayout(
          currentlyWatching,
          flipBacklogUpward: () {
            upward = !upward;

            MiscSettings.setAnimeWatchingOrderReversed(upward);

            setState(() {});
          },
          backlogUpward: upward,
          watchingRight: right,
          flipWatchingRight: () {
            right = !right;

            setState(() {});
          },
        ),
        refreshingStatus: state.refreshingStatus,
        getCell: _getCell,
        imageViewDescription: ImageViewDescription(
          imageViewKey: state.imageViewKey,
        ),
        functionality: GridFunctionality(
          selectionGlue:
              GlueProvider.generateOf<AnimeEntry, SavedAnimeEntry>(context),
          refresh: SynchronousGridRefresh(() => backlog.length),
          onPressed:
              OverrideGridOnCellPressBehaviour(onPressed: (context, idx, _) {
            final cell = CellProvider.getOf<SavedAnimeEntry>(context, idx);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return WatchingAnimeInfoPage(entry: cell);
              },
            ));
          }),
        ),
        systemNavigationInsets: widget.viewInsets,
        mainFocus: state.mainFocus,
        description: GridDescription(
          risingAnimation: true,
          actions: [
            GridAction(Icons.play_arrow_rounded, (selected) {
              final entry = selected.first;

              if (!entry.inBacklog) {
                entry.unsetIsWatching();
                return;
              }

              if (!entry.setCurrentlyWatching()) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.cantWatchThree)));
              }
            }, true, showOnlyWhenSingle: true),
            GridAction(
              Icons.delete_rounded,
              (selected) {
                SavedAnimeEntry.deleteAll(
                  selected.map((e) => e.isarId!).toList(),
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Deleted from backlog"),
                  action: SnackBarAction(
                      label: "Undo",
                      onPressed: () {
                        SavedAnimeEntry.addAll(selected, selected.first.site);
                      }),
                ));
              },
              true,
            ),
            GridAction(Icons.check_rounded, (selected) {
              WatchedAnimeEntry.moveAll(selected);
            }, true),
          ],
          keybindsDescription: AppLocalizations.of(context)!.watchingTab,
          showAppBar: false,
          ignoreSwipeSelectGesture: true,
          ignoreEmptyWidgetOnNoContent: true,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
      overrideOnPop: (pop, hideAppBar) {
        if (hideAppBar()) {
          setState(() {});
          return;
        }

        widget.procPop(pop);
      },
    );
  }
}

class _WatchingLayout
    implements GridLayouter<SavedAnimeEntry>, GridLayoutBehaviour {
  const _WatchingLayout(
    this.currentlyWatching, {
    required this.backlogUpward,
    required this.flipBacklogUpward,
    required this.flipWatchingRight,
    required this.watchingRight,
  });

  final bool backlogUpward;
  final void Function() flipBacklogUpward;

  final bool watchingRight;
  final void Function() flipWatchingRight;

  final List<SavedAnimeEntry> currentlyWatching;

  @override
  GridLayouter<T> makeFor<T extends Cell>(GridSettingsBase settings) {
    return this as GridLayouter<T>;
  }

  @override
  bool get isList => false;

  static GridSettingsBase _defaultSettings() => const GridSettingsBase(
        aspectRatio: GridAspectRatio.zeroSeven,
        columns: GridColumn.three,
        layoutType: GridLayoutType.grid,
        hideName: false,
      );

  @override
  GridSettingsBase Function() get defaultSettings => _defaultSettings;

  @override
  List<Widget> call(BuildContext context, GridSettingsBase gridSettings,
      GridFrameState<SavedAnimeEntry> state) {
    void onPressed(SavedAnimeEntry e, int _) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return WatchingAnimeInfoPage(entry: e);
        },
      ));
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: SliverToBoxAdapter(
          child: MediumSegmentLabel(
            AppLocalizations.of(context)!.watchingLabel,
            trailingWidget: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: flipWatchingRight,
              icon: (watchingRight
                      ? const Icon(Icons.arrow_back)
                      : const Icon(Icons.arrow_forward))
                  .animate(key: ValueKey(watchingRight))
                  .fadeIn(),
            ),
          ),
        ),
      ),
      if (currentlyWatching.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            children: watchingRight
                ? currentlyWatching.reversed.indexed
                    .map((e) => ImportantCard(
                          cell: e.$2,
                          idx: e.$1,
                          onPressed: onPressed,
                        ).animate(key: ValueKey(e)).fadeIn())
                    .toList()
                : currentlyWatching.indexed
                    .map(
                      (e) => ImportantCard(
                        idx: e.$1,
                        cell: e.$2,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn(),
                    )
                    .toList(),
          ),
        )
      else
        SliverToBoxAdapter(
            child: EmptyWidget(
          gridSeed: state.widget.description.gridSeed,
        )),
      SliverPadding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        sliver: SliverToBoxAdapter(
          child: MediumSegmentLabel(
            AppLocalizations.of(context)!.backlogLabel,
            trailingWidget: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: flipBacklogUpward,
              icon: (backlogUpward
                      ? const Icon(Icons.arrow_upward)
                      : const Icon(Icons.arrow_downward))
                  .animate(key: ValueKey(backlogUpward))
                  .fadeIn(),
            ),
          ),
        ),
      ),
      if (state.mutation.cellCount > 0)
        SliverPadding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          sliver: GridLayout.blueprint<SavedAnimeEntry>(
            context,
            state.mutation,
            state.selection,
            systemNavigationInsets: 0,
            aspectRatio: gridSettings.aspectRatio.value,
            columns: gridSettings.columns.number,
            gridCell: (context, idx) {
              return GridCell.frameDefault(
                context,
                idx,
                hideTitle: gridSettings.hideName,
                isList: isList,
                state: state,
                animated: true,
              );
            },
          ),
        )
      else
        SliverToBoxAdapter(
            child: EmptyWidget(
          gridSeed: state.widget.description.gridSeed + 1,
        )),
    ];
  }
}

class ImportantCard<T extends Cell> extends StatelessWidget {
  final T cell;
  final int idx;
  final void Function(T cell, int idx) onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  const ImportantCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return UnsizedCard(
      leanToLeft: false,
      subtitle: Text(cell.alias(false)),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          indx: 0,
          onPressed: null,
          tight: true,
          hideAlias: true,
          download: null,
          isList: false,
          circle: true,
        ),
      ),
      backgroundImage: cell.thumbnail(),
      tooltip: cell.alias(false),
      onLongPressed: onLongPressed == null
          ? null
          : () {
              onLongPressed!(cell, idx);
            },
      onPressed: () {
        onPressed(cell, idx);
      },
    );
  }
}
