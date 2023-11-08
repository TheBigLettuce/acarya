// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class SelectionData extends InheritedWidget {
  final SelectionCallbackBundle bundle;

  const SelectionData({super.key, required this.bundle, required super.child});

  static SelectionCallbackBundle of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<SelectionData>();

    return widget!.bundle;
  }

  @override
  bool updateShouldNotify(SelectionData oldWidget) =>
      oldWidget.bundle != bundle;
}

class SelectionCallbackBundle {
  final void Function(BuildContext context, int i) selectUnselect;
  final void Function(BuildContext context, int i) selectUntil;
  final bool Function(BuildContext context, int i) isSelected;

  const SelectionCallbackBundle({
    required this.isSelected,
    required this.selectUnselect,
    required this.selectUntil,
  });
}
