// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/isar.dart';
import '../schemas/download_file.dart';
import '../schemas/settings.dart';
import '../booru/tags/tags.dart';
import '../widgets/search_launch_grid.dart';

class BooruScroll extends StatefulWidget {
  final GridTab grids;
  final String tags;
  final double initalScroll;
  final bool clear;
  final int? booruPage;
  final double? pageViewScrollingOffset;
  final int? initalPost;
  final bool toRestore;
  final DateTime? time;

  final Isar? currentInstance;
  final bool isPrimary;

  const BooruScroll.primary({
    super.key,
    required this.initalScroll,
    required this.grids,
    required this.time,
    required this.booruPage,
    this.clear = false,
  })  : tags = "",
        toRestore = false,
        pageViewScrollingOffset = null,
        initalPost = null,
        currentInstance = null,
        isPrimary = true;

  const BooruScroll.secondary({
    super.key,
    required this.grids,
    required Isar instance,
    required this.tags,
  })  : initalScroll = 0,
        clear = true,
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        time = null,
        currentInstance = instance,
        isPrimary = false;

  const BooruScroll.restore(
      {super.key,
      required this.grids,
      required Isar instance,
      required this.pageViewScrollingOffset,
      required this.initalPost,
      required this.tags,
      required this.booruPage,
      required this.initalScroll})
      : clear = false,
        toRestore = true,
        currentInstance = instance,
        time = null,
        isPrimary = false;

  @override
  State<BooruScroll> createState() => BooruScrollState();
}

class BooruScrollState extends State<BooruScroll> with SearchLaunchGrid {
  //late Isar isar = widget.isar;
  //late StreamSubscription<void> tagWatcher;
  late StreamSubscription<Settings?> settingsWatcher;
  //List<String> tags = BooruTags().latest.getStrings();
  late final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;
  Downloader downloader = Downloader();
  bool reachedEnd = false;

  late GridSkeletonState skeletonState = GridSkeletonState(
      index: kBooruGridDrawerIndex,
      onWillPop: () {
        if (widget.isPrimary) {
          if (widget.toRestore) {
            widget.grids
                .restoreStateNext(context, widget.currentInstance!.name);
          }
        }

        return Future.value(true);
      });

  @override
  void initState() {
    super.initState();

    searchHook(SearchLaunchGridData(skeletonState.mainFocus, widget.tags));

    if (widget.isPrimary) {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          widget.grids
              .updateScroll(booru, pos, booru.currentPage, tagPos: infoPos);
    } else {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          widget.grids.updateScrollSecondary(
              widget.currentInstance!, pos, widget.tags, booru.currentPage,
              scrollPositionTags: infoPos, selectedPost: selectedCell);
    }

    if (widget.clear) {
      if (widget.isPrimary) {
        widget.grids.instance
            .writeTxnSync(() => widget.grids.instance.posts.clearSync());
      } else {
        widget.currentInstance!
            .writeTxnSync(() => widget.currentInstance!.posts.clearSync());
      }
    }

    // tagWatcher = db.isar().lastTags.watchLazy().listen((_) {
    //   tags = BooruTags().latest.getStrings();
    // });

    settingsWatcher = db.settingsIsar().settings.watchObject(0).listen((event) {
      skeletonState.settings = event!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    //  tagWatcher.cancel();
    settingsWatcher.cancel();

    if (!widget.isPrimary) {
      widget.grids.removeSecondaryGrid(widget.currentInstance!.name);
    } else {
      widget.grids.close();
    }

    disposeSearch();

    skeletonState.dispose();

    booru.close();

    super.dispose();
  }

  // List<String> _searchFilter(String value) => value.isEmpty
  //     ? []
  //     : tags.where((element) => element.contains(value)).toList();

  Isar _getInstance() =>
      widget.isPrimary ? widget.grids.instance : widget.currentInstance!;

  Future<int> _clearAndRefresh() async {
    // try {

    // } catch (e, trace) {
    //   log("refreshing grid on ${skeletonState.settings.selectedBooru.string}",
    //       level: Level.WARNING.value, error: e, stackTrace: trace);
    // }

    var list = await booru.page(0, widget.tags, widget.grids.excluded);
    updateScrollPosition(0);
    var instance = _getInstance();
    await instance.writeTxn(() {
      instance.posts.clear();
      return instance.posts.putAllById(list);
    });
    PostTags().addAllPostTags(list);
    reachedEnd = false;

    return instance.posts.count();
  }

  Future<void> _download(int i) async {
    var instance = _getInstance();

    var p = instance.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    return downloader.add(File.d(p.downloadUrl(), booru.domain, p.filename()));
  }

  Future<int> _addLast() async {
    var instance = _getInstance();

    if (reachedEnd) {
      return instance.posts.countSync();
    }
    var p = instance.posts.getSync(instance.posts.countSync());
    if (p == null) {
      return instance.posts.countSync();
    }

    try {
      var list = await booru.fromPost(p.id, widget.tags, widget.grids.excluded);
      if (list.isEmpty) {
        reachedEnd = true;
      } else {
        instance.writeTxnSync(() => instance.posts.putAllByIdSync(list));
        PostTags().addAllPostTags(list);
      }
    } catch (e, trace) {
      log("_addLast on grid ${skeletonState.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return instance.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton(
      context,
      skeletonState,
      CallbackGrid<Post, PostShrinked>(
        key: skeletonState.gridKey,
        systemNavigationInsets: insets,
        description: GridDescription(
          kBooruGridDrawerIndex,
          [
            GridBottomSheetAction(Icons.download, (selected) {
              for (var element in selected) {
                downloader.add(
                    File.d(element.fileUrl, booru.domain, element.fileName));
              }
            }, true)
          ],
          skeletonState.settings.picturesPerRow,
          time: booru.wouldBecomeStale ? widget.time : null,
          keybindsDescription: AppLocalizations.of(context)!.booruGridPageName,
        ),
        hasReachedEnd: () => reachedEnd,
        mainFocus: skeletonState.mainFocus,
        scaffoldKey: skeletonState.scaffoldKey,
        aspectRatio: skeletonState.settings.ratio.value,
        getCell: (i) => _getInstance().posts.getSync(i + 1)!,
        loadNext: _addLast,
        refresh: _clearAndRefresh,
        hideShowFab: ({required bool fab, required bool foreground}) =>
            skeletonState.updateFab(setState, fab: fab, foreground: foreground),
        onBack: widget.tags.isEmpty
            ? null
            : () {
                if (widget.toRestore) {
                  widget.grids
                      .restoreStateNext(context, widget.currentInstance!.name);
                } else {
                  Navigator.pop(context);
                }
              },
        //  searchStartingValue: widget.tags,
        // search: _search,
        hideAlias: true,
        download: _download,
        updateScrollPosition: updateScrollPosition,
        initalScrollPosition: widget.initalScroll,
        initalCellCount: widget.clear ? 0 : _getInstance().posts.countSync(),
        searchWidget:
            SearchAndFocus(searchWidget(context), searchFocus, onPressed: () {
          if (currentlyHighlightedTag != "") {
            skeletonState.mainFocus.unfocus();
            widget.grids.onTagPressed(
                context, Tag.string(tag: currentlyHighlightedTag));
          }
        }),
        //  searchFilter: _searchFilter,
        pageViewScrollingOffset: widget.pageViewScrollingOffset,
        initalCell: widget.initalPost,
      ),
    );
  }
}
