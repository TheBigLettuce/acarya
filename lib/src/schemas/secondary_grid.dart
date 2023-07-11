// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

part 'secondary_grid.g.dart';

@collection
class SecondaryGrid {
  final Id id = 0;

  final String tags;

  final double scrollPositionGrid;

  final int? selectedPost;
  final double? scrollPositionTags;
  final int? page;

  const SecondaryGrid(this.tags, this.scrollPositionTags, this.selectedPost,
      this.scrollPositionGrid,
      {this.page});
}
