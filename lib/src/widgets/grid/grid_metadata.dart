// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/grid/search_and_focus.dart';

import 'grid_action.dart';

/// Displayed in the keybinds info page name.
// final String keybindsDescription;

/// If [pageName] is not null, and [CallbackGridShell.searchWidget] is null,
/// then a Text widget will be displayed in the app bar with this value.
/// If null and [CallbackGridShell.searchWidget] is null, then [keybindsDescription] is used as the value.
// final String? pageName;

/// Actions of the grid on selected cells.
// final List<GridAction<T>> actions;

// final GridLayouter<T> layout;

/// Displayed in the app bar bottom widget.
// final PreferredSizeWidget? bottomWidget;

// final bool showAppBar;

/// Metadata about the grid.
// class GridDescription1 {
//   final GridColumn columns;
//   final GridAspectRatio aspectRatio;

//   const GridDescription1(
//     this.actions, {
//     this.showAppBar = true,
//     required this.keybindsDescription,
//     this.bottomWidget,
//     this.pageName,
//     // required this.layout,
//   });
// }

class GridMetadata<T extends Cell> {
  /// Actions of the grid on selected cells.
  final List<GridAction<T>> gridActions;

  final List<Widget> appBarActions;

  final SearchAndFocus? search;

  final bool tight;

  final bool hideAlias;

  final void Function(BuildContext, T)? overrideOnPress;

  const GridMetadata({
    this.appBarActions = const [],
    required this.gridActions,
    this.hideAlias = false,
    this.tight = false,
    this.overrideOnPress,
    this.search,
  });
}

// abstract class GridLayouter {
//   Widget call(BuildContext context, CallbackGridShellState<T> state);
//   GridColumn? get columns;
//   bool get isList;

//   const GridLayouter();
// }
