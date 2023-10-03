// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';

import '../../db/schemas/settings.dart';
import '../../interfaces/cell.dart';
import '../grid/callback_grid.dart';
import 'skeleton_state.dart';

class GridSkeletonState<T extends Cell> extends SkeletonState {
  bool showFab;
  final GlobalKey<CallbackGridState<T>> gridKey = GlobalKey();
  Settings settings = Settings.fromDb();
  // final Future<bool> Function() onWillPop;

  void updateFab(void Function(void Function()) setState,
      {required bool fab, required bool foreground}) {
    if (fab != showFab) {
      showFab = fab;
      if (!foreground) {
        try {
          setState(() {});
        } catch (_) {}
      }
    }
  }

  GridSkeletonState({required int index})
      : showFab = false,
        super(index);
}
