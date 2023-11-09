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
import 'package:gallery/src/widgets/grid/segments.dart';
import 'package:gallery/src/widgets/notifiers/get_cell.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';

import '../../app_bar/wrap_badge_cell_count_title_widget.dart';
import '../../cell.dart';
import '../../notifiers/grid_mutation_interface_holder.dart';
import '../../notifiers/grid_selection_holder.dart';
import '../../notifiers/wrap_grid_status_notifiers.dart';
import '../../wrapped_selection.dart';

part 'body.dart';

class GridLayout<T extends Cell> extends StatefulWidget {
  final GridColumn columns;
  final GridAspectRatio aspectRatio;

  final GridMetadata<T> metadata;

  final void Function(T)? download;

  final Segments<T>? segments;

  final BackgroundDataLoader<T, int> loader;

  const GridLayout(
      {super.key,
      required this.aspectRatio,
      required this.columns,
      required this.download,
      required this.loader,
      this.segments,
      required this.metadata});

  @override
  State<GridLayout<T>> createState() => _GridLayoutState<T>();
}

class _GridLayoutState<T extends Cell> extends State<GridLayout<T>> {
  void _download(BuildContext context, int i) {
    widget.download!(widget.loader.getSingle(i)!);
  }

  void _onPressed(BuildContext context, T cell, int idx) {
    if (widget.metadata.overrideOnPress != null) {
      widget.metadata.overrideOnPress!(context, cell);
      return;
    }
  }

  Future<void> _refresh() {
    return Future.value();
  }

  void _onAppBarTitlePressed() {}

  @override
  Widget build(BuildContext context) {
    return DataLoaderHolder<T>(
      loader: widget.loader,
      child: GridSelectionHolder<T>(
          child: CallbackGridBase<T>(
        onRefresh: _refresh,
        appBar: GridAppBar(
            actions: widget.metadata.appBarActions,
            bottomWidget: null,
            centerTitle: true,
            leading: Text(""),
            search: widget.metadata.search,
            title: GridAppBarTitle(
                onPressed: _onAppBarTitlePressed,
                searchWidget: widget.metadata.search,
                child: const WrapBadgeCellCountTitleWidget(
                  child: SearchCharacterTitle(),
                ))),
        child: _GridBody(
          aspectRatio: widget.aspectRatio,
          columns: widget.columns,
          metadata: widget.metadata,
          download: widget.download == null ? null : _download,
          onPressed: _onPressed,
        ),
      )),
    );
  }
}
