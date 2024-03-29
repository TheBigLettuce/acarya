// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';

class PagingContainer<T extends Cell, J> {
  PagingContainer(this.extra);

  final J extra;

  int page = 0;
  double scrollPos = 0;

  bool reachedEnd = false;

  late final GridRefreshingStatus<T> refreshingStatus =
      GridRefreshingStatus<T>(0, () => reachedEnd);

  void dispose() {
    refreshingStatus.dispose();
  }

  void updateScrollPos(double pos) {
    scrollPos = pos;
  }
}
