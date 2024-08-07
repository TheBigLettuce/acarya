// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:flutter/material.dart";

class GridLayout<T extends CellBase> extends StatefulWidget {
  const GridLayout({
    super.key,
    required this.source,
    this.buildEmpty,
    required this.progress,
    this.unselectOnUpdate = true,
  });

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;
  final bool unselectOnUpdate;

  @override
  State<GridLayout<T>> createState() => _GridLayoutState();
}

class _GridLayoutState<T extends CellBase> extends State<GridLayout<T>> {
  ReadOnlyStorage<int, T> get source => widget.source;

  late final StreamSubscription<int> _watcher;

  @override
  void initState() {
    _watcher = source.watch((_) {
      if (widget.unselectOnUpdate) {
        GridExtrasNotifier.of<T>(context).selection.reset();
      }

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
    final config = GridConfiguration.of(context);

    return EmptyWidgetOrContent(
      count: source.count,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: config.aspectRatio.value,
          crossAxisCount: config.columns.number,
        ),
        itemCount: source.count,
        itemBuilder: (context, idx) {
          final cell = getCell(idx);

          return WrapSelection<T>(
            selection: extras.selection,
            thisIndx: idx,
            onPressed: cell.tryAsPressable(context, extras.functionality, idx),
            description: cell.description(),
            functionality: extras.functionality,
            selectFrom: null,
            child: GridCell.frameDefault(
              context,
              idx,
              cell,
              hideTitle: config.hideName,
              isList: false,
              imageAlign: Alignment.center,
              animated: PlayAnimations.maybeOf(context) ?? false,
            ),
          );
        },
      ),
    );
  }
}

class EmptyWidgetOrContent extends StatefulWidget {
  const EmptyWidgetOrContent({
    super.key,
    required this.count,
    required this.progress,
    required this.buildEmpty,
    required this.child,
  });

  final int count;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  final Widget child;

  @override
  State<EmptyWidgetOrContent> createState() => _EmptyWidgetOrContentState();
}

class _EmptyWidgetOrContentState extends State<EmptyWidgetOrContent> {
  late final StreamSubscription<bool> _watcher;

  @override
  void initState() {
    _watcher = widget.progress.watch((_) {
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
    return widget.count == 0 && !widget.progress.inRefreshing
        ? SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverToBoxAdapter(
              child: widget.buildEmpty?.call(widget.progress.error) ??
                  EmptyWidget(
                    gridSeed: 0,
                    error: widget.progress.error == null
                        ? null
                        : EmptyWidget.unwrapDioError(
                            widget.progress.error,
                          ),
                  ),
            ),
          )
        : widget.child;
  }
}

class EmptyWidgetWithButton extends StatelessWidget {
  const EmptyWidgetWithButton({
    super.key,
    this.overrideText,
    required this.error,
    required this.onPressed,
    required this.buttonText,
  });

  final String? overrideText;
  final Object? error;
  final void Function() onPressed;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EmptyWidget(
          gridSeed: 0,
          overrideEmpty: overrideText,
          error: error == null
              ? null
              : EmptyWidget.unwrapDioError(
                  error,
                ),
        ),
        const Padding(padding: EdgeInsets.only(top: 4)),
        FilledButton.tonal(onPressed: onPressed, child: Text(buttonText)),
      ],
    );
  }
}
