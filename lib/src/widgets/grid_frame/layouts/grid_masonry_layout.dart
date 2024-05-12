// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";

class GridMasonryLayout<T extends CellBase> extends StatelessWidget {
  const GridMasonryLayout({
    super.key,
    required this.randomNumber,
  });

  final int randomNumber;

  @override
  Widget build(BuildContext context) {
    final getCell = CellProvider.of<T>(context);
    final extras = GridExtrasNotifier.of<T>(context);
    final config = GridConfiguration.of(context);

    final size = (MediaQuery.sizeOf(context).shortestSide * 0.95) /
        config.columns.number;

    return SliverMasonryGrid(
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.columns.number,
      ),
      delegate: SliverChildBuilderDelegate(
          childCount: extras.functionality.refreshingStatus.mutation.cellCount,
          (context, idx) {
        final cell = getCell(idx);

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

        final rem = ((randomNumber + idx) % 11) * 0.5;
        final maxHeight = (size / config.aspectRatio.value) +
            (rem *
                    (size *
                        (0.037 + (config.columns.number / 100) - rem * 0.01)))
                .toInt();

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: WrapSelection(
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
              imageAlign: Alignment.center,
              hideTitle: config.hideName,
              isList: false,
            ),
          ),
        );
      }),
    );
  }
}
