// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/add_rail.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/cell/booru.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/image/cells.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as sc_pos;
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/system_gestures.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../schemas/download_file.dart';
import '../schemas/secondary_grid.dart';
import '../schemas/settings.dart';
import 'tags/tags.dart';

void _updateScrollPrimary(double pos, int? page, {double? tagPos}) {
  db.isar().writeTxnSync(() => db.isar().scrollPositionPrimarys.putSync(
      sc_pos.ScrollPositionPrimary(pos, db.getBooru().domain(),
          page: page, tagPos: tagPos)));
}

void _updateScrollSecondary(Isar isar, double pos, String tags, int? page,
    {int? selectedPost, double? scrollPositionTags}) {
  isar.writeTxnSync(() => isar.secondaryGrids.putSync(
      SecondaryGrid(tags, scrollPositionTags, selectedPost, pos, page: page)));
}

class BooruScroll extends StatefulWidget {
  final Isar isar;
  final String tags;
  final double initalScroll;
  final bool clear;
  final int? booruPage;
  final double? pageViewScrollingOffset;
  final int? initalPost;
  final bool toRestore;

  // ignore: unused_field
  final String _type; // for debug only

  final void Function(String path)? closeDb;

  const BooruScroll.primary({
    super.key,
    required this.initalScroll,
    required this.isar,
    this.clear = false,
  })  : tags = "",
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        closeDb = null,
        _type = "primary";

  const BooruScroll.secondary({
    super.key,
    required this.isar,
    required this.tags,
  })  : initalScroll = 0,
        clear = true,
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        closeDb = db.removeSecondaryGrid,
        _type = "secondary";

  const BooruScroll.restore(
      {super.key,
      required this.isar,
      required this.pageViewScrollingOffset,
      required this.initalPost,
      required this.tags,
      required this.booruPage,
      required this.initalScroll})
      : clear = false,
        toRestore = true,
        closeDb = db.removeSecondaryGrid,
        _type = "restore";

  @override
  State<BooruScroll> createState() => _BooruScrollState();
}

class _BooruScrollState extends State<BooruScroll> {
  late BooruAPI booru = db.getBooru(page: widget.booruPage);
  late Isar isar = widget.isar;
  late Settings settings = db.isar().settings.getSync(0)!;
  late StreamSubscription<void> tagWatcher;
  late StreamSubscription<Settings?> settingsWatcher;
  List<String> tags = BooruTags().getLatest();
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  late final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;
  Downloader downloader = Downloader();
  bool reachedEnd = false;

  @override
  void initState() {
    super.initState();

    if (widget.tags.isEmpty) {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          _updateScrollPrimary(pos, booru.currentPage(), tagPos: infoPos);
    } else {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          _updateScrollSecondary(
              widget.isar, pos, widget.tags, booru.currentPage(),
              scrollPositionTags: infoPos, selectedPost: selectedCell);
    }

    if (widget.clear) {
      isar.writeTxnSync(() => isar.posts.clearSync());
    }

    tagWatcher = db.isar().lastTags.watchLazy().listen((_) {
      tags = BooruTags().getLatest();
    });

    settingsWatcher = db.isar().settings.watchObject(0).listen((event) {
      setState(() {
        settings = event!;
      });
    });
  }

  @override
  void dispose() {
    tagWatcher.cancel();
    settingsWatcher.cancel();

    if (widget.closeDb != null) {
      widget.closeDb!(isar.name);
    }

    super.dispose();
  }

  List<String> _searchFilter(String value) => value.isEmpty
      ? []
      : tags.where((element) => element.contains(value)).toList();

  Future<int> _clearAndRefresh() async {
    try {
      var list = await booru.page(0, widget.tags);
      updateScrollPosition(0);
      await isar.writeTxn(() {
        isar.posts.clear();
        return isar.posts.putAllById(list);
      });
      reachedEnd = false;
    } catch (e, trace) {
      log("refreshing grid on ${settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return isar.posts.count();
  }

  void _search(String t) => tagOnPressed(context, t);

  Future<void> _download(int i) async {
    var p = isar.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    return downloader.add(File.d(p.fileUrl, booru.domain(), p.filename()));
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return isar.posts.countSync();
    }
    var p = isar.posts.getSync(isar.posts.countSync());
    if (p == null) {
      return isar.posts.countSync();
    }

    try {
      var list = await booru.fromPost(p.id, widget.tags);
      if (list.isEmpty) {
        reachedEnd = true;
      } else {
        isar.writeTxnSync(() => isar.posts.putAllByIdSync(list));
      }
    } catch (e, trace) {
      log("_addLast on grid ${settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return isar.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.tags.isNotEmpty) {
          if (widget.toRestore) {
            db.restoreStateNext(context, isar.name);
          }
        }

        return Future.value(true);
      },
      child: Scaffold(
          key: _key,
          drawer: makeDrawer(context, 0, true),
          body: gestureDeadZones(
            context,
            child: addRail(
                context,
                0,
                true,
                CellsWidget<BooruCell>(
                  hasReachedEnd: () => reachedEnd,
                  scaffoldKey: _key,
                  getCell: (i) => isar.posts.getSync(i + 1)!.booruCell(_search),
                  loadNext: _addLast,
                  refresh: _clearAndRefresh,
                  onBack: widget.tags.isEmpty
                      ? null
                      : () {
                          if (widget.toRestore) {
                            db.restoreStateNext(context, isar.name);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                  searchStartingValue: widget.tags,
                  search: _search,
                  hideAlias: true,
                  onLongPress: _download,
                  updateScrollPosition: updateScrollPosition,
                  initalScrollPosition: widget.initalScroll,
                  initalCellCount: widget.clear ? 0 : isar.posts.countSync(),
                  searchFilter: _searchFilter,
                  pageViewScrollingOffset: widget.pageViewScrollingOffset,
                  initalCell: widget.initalPost,
                )),
          )),
    );
  }
}
