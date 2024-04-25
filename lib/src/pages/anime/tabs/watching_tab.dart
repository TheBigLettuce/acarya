// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../anime.dart";

class _WatchingTab extends StatefulWidget {
  const _WatchingTab({
    required super.key,
    required this.procPop,
    required this.onDispose,
  });

  final void Function() onDispose;
  final void Function(bool) procPop;

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
  final GlobalKey<__CurrentlyWatchingState> watchingKey = GlobalKey();

  bool upward = MiscSettings.current.animeWatchingOrderReversed;
  bool right = false;
  String _filteringValue = "";

  void filter(String value) {
    final m = state.gridKey.currentState?.mutation;
    if (m == null) {
      return;
    }

    _filteringValue = value.trim();

    final l = _filteringValue.toLowerCase();

    _backlogFilter.clear();
    _watchingFilter.clear();

    if (_filteringValue.isEmpty) {
      setState(() {});

      m.cellCount = backlog.length;

      return;
    }

    _backlogFilter.addAll(
      backlog.where((element) => element.title.toLowerCase().contains(l)),
    );
    _watchingFilter.addAll(
      currentlyWatching
          .where((element) => element.title.toLowerCase().contains(l)),
    );

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
          watchingKey: watchingKey,
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
        getCell: _getCell,
        functionality: GridFunctionality(
          selectionGlue: GlueProvider.generateOf(context)(),
          refreshingStatus: state.refreshingStatus,
          refresh: SynchronousGridRefresh(() => backlog.length),
        ),
        mainFocus: state.mainFocus,
        description: GridDescription(
          actions: [
            GridAction(
              Icons.play_arrow_rounded,
              (selected) {
                final entry = selected.first;

                if (!entry.inBacklog) {
                  entry.unsetIsWatching();
                  return;
                }

                if (!entry.setCurrentlyWatching()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.cantWatchThree),
                    ),
                  );
                }
              },
              true,
              showOnlyWhenSingle: true,
            ),
            GridAction(
              Icons.delete_rounded,
              (selected) {
                SavedAnimeEntry.deleteAll(
                  selected.map((e) => (e.site, e.id)).toList(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.deletedFromBacklog),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.undoLabel,
                      onPressed: () {
                        SavedAnimeEntry.reAdd(selected);
                      },
                    ),
                  ),
                );
              },
              true,
            ),
            const GridAction(
              Icons.check_rounded,
              WatchedAnimeEntry.moveAll,
              true,
            ),
          ],
          keybindsDescription: AppLocalizations.of(context)!.watchingTab,
          showAppBar: false,
          ignoreEmptyWidgetOnNoContent: true,
          gridSeed: state.gridSeed,
        ),
      ),
      canPop: false,
      secondarySelectionHide: () {
        watchingKey.currentState?.selection.reset();
      },
      onPop: widget.procPop,
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
    required this.watchingKey,
  });

  final GlobalKey<__CurrentlyWatchingState> watchingKey;

  final bool backlogUpward;
  final void Function() flipBacklogUpward;

  final bool watchingRight;
  final void Function() flipWatchingRight;

  final List<SavedAnimeEntry> currentlyWatching;

  @override
  GridLayouter<T> makeFor<T extends CellBase>(GridSettingsBase settings) {
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
  List<Widget> call(
    BuildContext context,
    GridSettingsBase gridSettings,
    GridFrameState<SavedAnimeEntry> state,
  ) {
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
          sliver: _CurrentlyWatching(
            key: watchingKey,
            currentlyWatching: currentlyWatching,
            watchingRight: watchingRight,
            controller: state.controller,
            glue: GlueProvider.generateOf(context)(),
          ),
        )
      else
        SliverToBoxAdapter(
          child: EmptyWidget(
            gridSeed: state.widget.description.gridSeed,
          ),
        ),
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
            state.widget.functionality,
            state.selection,
            aspectRatio: gridSettings.aspectRatio.value,
            columns: gridSettings.columns.number,
            gridCell: (context, cell, idx) {
              return GridCell.frameDefault(
                context,
                idx,
                cell,
                imageAlign: Alignment.topCenter,
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
          ),
        ),
    ];
  }
}

class _CurrentlyWatching extends StatefulWidget {
  const _CurrentlyWatching({
    super.key,
    required this.currentlyWatching,
    required this.controller,
    required this.watchingRight,
    required this.glue,
  });

  final bool watchingRight;
  final List<SavedAnimeEntry> currentlyWatching;
  final ScrollController controller;
  final SelectionGlue glue;

  @override
  State<_CurrentlyWatching> createState() => __CurrentlyWatchingState();
}

class __CurrentlyWatchingState extends State<_CurrentlyWatching> {
  late final selection = GridSelection<SavedAnimeEntry>(
    [
      GridAction(
        Icons.play_arrow_rounded,
        (selected) {
          SavedAnimeEntry.unsetIsWatchingAll(selected.cast());
        },
        true,
      ),
      GridAction(
        Icons.delete_rounded,
        (selected) {
          SavedAnimeEntry.deleteAll(selected.cast());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deletedFromBacklog),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.undoLabel,
                onPressed: () {
                  SavedAnimeEntry.reAdd(selected.cast());
                },
              ),
            ),
          );
        },
        true,
      ),
      GridAction(
        Icons.check_rounded,
        (selected) {
          WatchedAnimeEntry.moveAll(selected.cast());
        },
        true,
      ),
    ],
    widget.glue,
    () => widget.controller,
    mutation: StaticNumberGridMutation(() => widget.currentlyWatching.length),
    noAppBar: true,
    // ignoreSwipe: true,
  );

  void onPressed(SavedAnimeEntry e, int _) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return AnimeInfoPage(
            entry: e,
            id: e.id,
            apiFactory: e.site.api,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CellProvider(
      getCell: (i) => widget.currentlyWatching[i],
      child: Builder(
        builder: (context) {
          return SliverGrid.count(
            crossAxisCount: 3,
            children: widget.watchingRight
                ? widget.currentlyWatching.reversed.indexed
                    .map(
                      (e) => ImportantCard(
                        cell: e.$2,
                        idx: e.$1,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn(),
                    )
                    .toList()
                : widget.currentlyWatching.indexed
                    .map(
                      (e) => ImportantCard(
                        cell: e.$2,
                        idx: e.$1,
                        onPressed: onPressed,
                      ).animate(key: ValueKey(e)).fadeIn(),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}

class MangaReadingCard<T extends CompactMangaData> extends StatelessWidget {
  const MangaReadingCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  void _onLongPressed() => onLongPressed!(cell, idx);

  void _onPressed() => onPressed!(cell, idx);

  @override
  Widget build(BuildContext context) {
    final lastRead = ReadMangaChapter.firstForId(cell.mangaId);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    return BaseCard(
      onLongPressed: onLongPressed == null ? null : _onLongPressed,
      subtitle: Text(
        cell.alias(false),
        maxLines: 2,
      ),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onPressed: onPressed == null ? null : _onPressed,
      width: null,
      height: null,
      footer: lastRead != null
          ? RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  if (lastRead.chapterName.isNotEmpty)
                    TextSpan(
                      text: "${lastRead.chapterName} ",
                      style: textTheme,
                    ),
                  TextSpan(
                    text:
                        "${lastRead.chapterNumber} - ${lastRead.chapterProgress}\n",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!
                        .date(lastRead.lastUpdated),
                    style: textTheme?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class ImportantCard<T extends CellBase> extends StatelessWidget {
  const ImportantCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

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
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onLongPressed: onLongPressed == null
          ? null
          : () {
              onLongPressed!(cell, idx);
            },
      onPressed: onPressed == null
          ? null
          : () {
              onPressed!(cell, idx);
            },
    );
  }
}
