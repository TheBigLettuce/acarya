// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

class ListLayout<T extends CellBase> extends StatefulWidget {
  const ListLayout({
    super.key,
    required this.hideThumbnails,
    required this.source,
    required this.progress,
    this.buildEmpty,
  });

  final bool hideThumbnails;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<ListLayout<T>> createState() => _ListLayoutState();
}

class _ListLayoutState<T extends CellBase> extends State<ListLayout<T>> {
  ReadOnlyStorage<int, T> get source => widget.source;

  late final StreamSubscription<int> _watcher;

  @override
  void initState() {
    _watcher = source.watch((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getCell = CellProvider.of<T>(context);
    final extras = GridExtrasNotifier.of<T>(context);

    return EmptyWidgetOrContent(
      count: source.count,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverPadding(
        padding: const EdgeInsets.only(right: 8, left: 8),
        sliver: SliverList.builder(
          itemCount: source.count,
          itemBuilder: (context, index) {
            final cell = getCell(index);

            return DefaultListTile(
              functionality: extras.functionality,
              selection: extras.selection,
              cell: cell,
              index: index,
              hideThumbnails: widget.hideThumbnails,
            );
          },
        ),
      ),
    );
  }
}

class DefaultListTile<T extends CellBase> extends StatelessWidget {
  const DefaultListTile({
    super.key,
    required this.functionality,
    required this.selection,
    required this.index,
    required this.cell,
    required this.hideThumbnails,
  });

  final GridFunctionality<T> functionality;
  final GridSelection<T> selection;
  final int index;
  final T cell;
  final bool hideThumbnails;

  @override
  Widget build(BuildContext context) {
    final thumbnail = cell.tryAsThumbnailable();

    return WrapSelection(
      selection: selection,
      selectFrom: null,
      limitedSize: true,
      description: cell.description(),
      onPressed: cell.tryAsPressable(context, functionality, index),
      functionality: functionality,
      thisIndx: index,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          SelectionCountNotifier.countOf(context);
          final isSelected = selection.isSelected(index);

          return DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: isSelected
                  ? null
                  : index.isOdd
                      ? theme.colorScheme.secondary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.1),
            ),
            child: ListTile(
              textColor: isSelected ? theme.colorScheme.inversePrimary : null,
              leading: !hideThumbnails && thumbnail != null
                  ? CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundImage: thumbnail,
                      onForegroundImageError: (_, __) {},
                    )
                  : null,
              title: Text(
                cell.alias(true),
                softWrap: false,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : index.isOdd
                          ? theme.colorScheme.onSurface.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    ).animate(key: cell.uniqueKey()).fadeIn();
  }
}
