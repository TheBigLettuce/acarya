// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/grid_state_booru.dart';
import 'package:isar/isar.dart';

import '../interfaces/tags.dart';
import '../pages/settings/settings_widget.dart';
import 'schemas/grid_state.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/booru.dart';
import '../pages/booru/random.dart';
import '../pages/booru/secondary.dart';
import 'schemas/settings.dart';
import 'schemas/tags.dart';
import 'booru_tagging.dart';
import 'initalize_db.dart';

part 'tag_manager.dart';

class StateRestoration {
  final Isar _mainGrid;
  final GridState copy;

  GridState get current => _mainGrid.gridStates.get(copy.name)!;

  void updateScrollPosition(double pos,
      {double? infoPos, int? selectedCell, int? page}) {
    final prev = _mainGrid.gridStates.get(copy.name)!;

    _mainGrid.write((i) => i.gridStates.put(prev.copy(false,
        scrollPositionGrid: pos,
        scrollPositionTags: infoPos,
        page: page,
        selectedPost: selectedCell)));
  }

  int secondaryCount() => _mainGrid.gridStates.count() - 1;

  void moveToBookmarks(Booru booru, int? page) {
    final prev = current;

    _mainGrid.write((i) => i.gridStates.delete(prev.name));

    Dbs.g.main.write((i) => i.gridStateBoorus.put(GridStateBooru(
          booru,
          tags: prev.tags,
          scrollPositionTags: prev.scrollPositionTags,
          selectedPost: prev.selectedPost,
          safeMode: prev.safeMode,
          scrollPositionGrid: prev.scrollPositionGrid,
          name: prev.name,
          time: prev.time,
          page: page,
        )));
  }

  void setSafeMode(SafeMode safeMode) {
    final prev = current;

    _mainGrid
        .write((i) => i.gridStates.put(prev.copy(false, safeMode: safeMode)));
  }

  void updateTime() {
    final prev = current;

    _mainGrid
        .write((i) => i.gridStates.put(prev.copy(false, time: DateTime.now())));
  }

  void removeScrollTagsSelectedPost() {
    if (isRestart) {
      return;
    }
    final prev = current;

    _mainGrid.write((i) => i.gridStates
        .put(prev.copy(true, scrollPositionTags: null, selectedPost: null)));
  }

  void removeSelf() {
    if (copy.name == _mainGrid.name) {
      throw "can't remove main grid's state";
    }

    _mainGrid.write((i) => i.gridStates.delete(copy.name));
  }

  StateRestoration insert(
      {required String tags,
      required String name,
      required SafeMode safeMode}) {
    _mainGrid.write((i) => i.gridStates
        .put(GridState.empty(name, tags, safeMode, DateTime.now())));
    return StateRestoration._new(_mainGrid, name, tags);
  }

  StateRestoration? next() {
    if (copy.name == _mainGrid.name) {
      throw "can't restore next in main StateRestoration";
    }

    _mainGrid.write((i) => i.gridStates.delete(copy.name));

    return last();
  }

  StateRestoration? last() {
    var res = _mainGrid.gridStates
        .where()
        .not()
        .nameEqualTo(_mainGrid.name)
        .sortByTimeDesc()
        .findFirst();
    if (res == null) {
      return null;
    }

    return StateRestoration._next(_mainGrid, res);
  }

  StateRestoration(Isar mainGrid, String name, SafeMode safeMode)
      : _mainGrid = mainGrid,
        copy = mainGrid.gridStates.get(name) ??
            GridState.empty(name, "", safeMode, DateTime.now()) {
    if (mainGrid.gridStates.get(name) == null) {
      mainGrid.write((i) => i.gridStates
          .put(GridState.empty(name, "", safeMode, DateTime.now())));
    }
  }

  StateRestoration._next(this._mainGrid, this.copy);

  StateRestoration._new(this._mainGrid, String name, String tags)
      : copy = _mainGrid.gridStates.get(name)!;
}
