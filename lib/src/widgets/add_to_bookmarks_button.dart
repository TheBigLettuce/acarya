// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';

import 'skeletons/grid_skeleton_state.dart';

class AddToBookmarksButton extends StatelessWidget {
  final GridSkeletonState state;
  final SelectionGlue glue;
  final void Function() f;

  const AddToBookmarksButton(
      {super.key, required this.state, required this.glue, required this.f});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          f();
          ScaffoldMessenger.of(state.scaffoldKey.currentContext!)
              .showSnackBar(const SnackBar(
                  content: Text(
            "Bookmarked", // TODO: change
          )));
          glue.close();
          state.gridKey.currentState?.selection.selected.clear();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.bookmark_add));
  }
}
