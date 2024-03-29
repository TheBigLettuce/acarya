// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';

import '../grid_frame.dart';

class GridMasonryLayout<T extends Cell> implements GridLayouter<T> {
  const GridMasonryLayout();

  @override
  bool get isList => false;

  @override
  List<Widget> call(BuildContext context, GridSettingsBase settings,
      GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.selection,
        columns: settings.columns.number,
        gridCell: (context, idx) => GridCell.frameDefault(
          context,
          idx,
          hideTitle: settings.hideName,
          isList: isList,
          state: state,
        ),
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: settings.aspectRatio.value,
        randomNumber: state.widget.description.gridSeed,
      )
    ];
  }

  static Widget blueprint<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection, {
    required MakeCellFunc<T> gridCell,
    required double systemNavigationInsets,
    required double aspectRatio,
    required int randomNumber,
    required int columns,
  }) {
    final size = (MediaQuery.sizeOf(context).shortestSide * 0.95) / columns;

    return SliverMasonryGrid(
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      delegate: SliverChildBuilderDelegate(childCount: state.cellCount,
          (context, indx) {
        // final cell = state.getCell(indx);

        // final n1 = switch (columns) {
        //   2 => 4,
        //   3 => 3,
        //   4 => 3,
        //   5 => 3,
        //   6 => 3,
        //   int() => 4,
        // };

        // final n2 = switch (columns) {
        //   2 => 40,
        //   3 => 40,
        //   4 => 30,
        //   5 => 30,
        //   6 => 20,
        //   int() => 40,
        // };

        // final int i = ((randomNumber + indx) % 5 + n1) * n2;

        final rem = ((randomNumber + indx) % 11) * 0.5;

        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: (size / aspectRatio) +
                  (rem * (size * (0.037 + (columns / 100) - rem * 0.01)))
                      .toInt()),
          child: WrapSelection(
            actionsAreEmpty: selection.addActions.isEmpty,
            selectionEnabled: selection.isNotEmpty,
            thisIndx: indx,
            ignoreSwipeGesture: selection.ignoreSwipe,
            bottomPadding: systemNavigationInsets,
            currentScroll: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(context, i),
            selectUnselect: () => selection.selectOrUnselect(context, indx),
            isSelected: selection.isSelected(indx),
            child: gridCell(context, indx),
          ),
        );
      }),
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns),
    );
  }
}
