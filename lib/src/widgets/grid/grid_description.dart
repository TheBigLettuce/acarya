// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

/// Metadata about the grid.
class GridDescription<T> {
  /// Index of the element in the drawer.
  /// Useful if the grid is displayed in the page which have entry in the drawer.
  final int drawerIndex;

  /// Displayed in the keybinds info page name.
  final String keybindsDescription;

  /// If [pageName] is not null, and [CallbackGrid.searchWidget] is null,
  /// then a Text widget will be displayed in the app bar with this value.
  /// If null and [CallbackGrid.searchWidget] is null, then [keybindsDescription] is used as the value.
  final String? pageName;

  /// Actions of the grid on selected cells.
  final List<GridBottomSheetAction<T>> actions;

  final GridColumn columns;

  /// If [listView] is true, then grid becomes a list.
  /// [CallbackGrid.segments] gets ignored if [listView] is true.
  final bool listView;

  /// Displayed in the app bar bottom widget.
  final PreferredSizeWidget? bottomWidget;

  const GridDescription(
    this.drawerIndex,
    this.actions,
    this.columns, {
    required this.keybindsDescription,
    this.bottomWidget,
    this.pageName,
    required this.listView,
  });
}