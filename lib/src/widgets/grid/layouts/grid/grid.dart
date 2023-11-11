// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/grid/callback_grid_base.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:gallery/src/widgets/grid/grid_app_bar.dart';
import 'package:gallery/src/widgets/grid/app_bar/grid_app_bar_title.dart';
import 'package:gallery/src/widgets/grid/grid_metadata.dart';
import 'package:gallery/src/widgets/grid/search_and_focus.dart';
import 'package:gallery/src/widgets/grid/segments.dart';
import 'package:gallery/src/widgets/notifiers/cell_provider.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';
import 'package:gallery/src/widgets/notifiers/state_restoration.dart';

import '../../app_bar/wrap_badge_cell_count_title_widget.dart';
import '../../cell.dart';
import '../../notifiers/grid_mutation_interface_holder.dart';
import '../../notifiers/grid_selection_holder.dart';
import '../../notifiers/wrap_grid_status_notifiers.dart';
import '../../wrapped_selection.dart';

class GridLayout<T extends Cell> extends StatelessWidget {
  final void Function(T)? download;

  final Segments<T>? segments;

  const GridLayout({super.key, this.download, this.segments});

  void _download(BuildContext context, int i) {
    download?.call(CellProvider.getOf<T>(context, i));
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio:
              GridMetadataProvider.aspectRatioOf<T>(context).value,
          crossAxisCount: GridMetadataProvider.columnsOf<T>(context).number),
      itemCount: GridElementCountNotifier.of(context),
      itemBuilder: (context, indx) {
        final t1 = DateTime.now();
        final cell = CellProvider.getOf<T>(context, indx);
        print(
            DateTime.now().microsecondsSinceEpoch - t1.microsecondsSinceEpoch);

        return WrappedSelection(
          thisIndx: indx,
          child: GridCell<T>(
            key: cell.uniqueKey(),
            cell: cell,
            indx: indx,
            download: _download,
          ),
        );
      },
    );
  }
}
