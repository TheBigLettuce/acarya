// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid/data_loaders/cell_loader.dart';
import '../../../interfaces/gallery.dart';
import '../../../interfaces/background_data_loader/control_message.dart';

part 'files.dart';

class AndroidGalleryDirectories implements GalleryAPIDirectories {
  const AndroidGalleryDirectories(this.loader);

  @override
  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {
    Dbs.g.blacklisted.write((i) => i.blacklistedDirectorys.putAll(bucketIds));
    loader.state.reset();
  }

  @override
  final BackgroundCellLoader<SystemGalleryDirectory, int> loader;

  @override
  GalleryAPIFiles joinedDir(
          List<String> directoriesId, GalleryFilesKind kind) =>
      AndroidGalleryFiles(
        kind.fromCache()
          ..send(ChangeContext(
              BackgroundCellLoader.filesResetContextState, directoriesId)),
        name: "",
        isTrash: false,
        isFavorites: false,
      );

  @override
  GalleryAPIFiles trash(GalleryFilesKind kind) => AndroidGalleryFiles(
        kind.fromCache()
          ..send(ChangeContext(
              BackgroundCellLoader.filesResetContextState, "trash")),
        isTrash: true,
        name: "trash",
      );

  @override
  GalleryAPIFiles favorites(GalleryFilesKind kind) => AndroidGalleryFiles(
        kind.fromCache()
          ..send(ChangeContext(
              BackgroundCellLoader.filesResetContextState, "favorites")),
        isFavorites: true,
        name: "favorites",
      );

  @override
  GalleryAPIFiles files(SystemGalleryDirectory d, GalleryFilesKind kind) =>
      AndroidGalleryFiles(
        kind.fromCache()
          ..send(ChangeContext(
              BackgroundCellLoader.filesResetContextState, d.bucketId)),
        name: d.name,
      );
}

  //  =.cached(
  //     kAndroidGalleryLoaderKey);

  // () => (
  //       (db, id) => null,
  //       _global!.db,
  //       [SystemGalleryDirectorySchema],
  //       (loader) => CellLoaderStateController(loader),
  //     )

  // void Function(int, bool)? temporarySet;

// @override
// void close() {
  // filter.dispose();
  // refreshGrid = null;
  // callback = null;
  // currentImages = null;
  // if (temporary == false) {
  //   _global!._unsetCurrentApi();
  // } else if (temporary == true) {
  //   _global!._temporaryApis.removeWhere((element) => element.time == time);
  // }
// }

  // @override
  // void setRefreshGridCallback(void Function() callback) {
  //   _impl.refreshGrid = callback;
  // }

  // @override
  // void setRefreshingStatusCallback(
  //     void Function(int i, bool inRefresh, bool empty) callback) {
  //   _impl.callback = callback;
  // }

  // @override
  // void setTemporarySet(void Function(int, bool) callback) {
  //   _impl.temporarySet = callback;
  // }

  // @override
  // void setPassFilter(
  //     (Iterable<SystemGalleryDirectory>, dynamic) Function(
  //             Iterable<SystemGalleryDirectory>, dynamic, bool)?
  //         filter) {
  //   _impl.filter.passFilter = filter;
  // }


  // final filter = IsarFilter<SystemGalleryDirectory>(
  //     _global!.db, DbsOpen.androidGalleryDirectories(temporary: true),
  //     (offset, limit, v, _, __) {
  //   return _global!.db.systemGalleryDirectorys
  //       .filter()
  //       .nameContains(v, caseSensitive: false)
  //       .or()
  //       .tagContains(v, caseSensitive: false)
  //       .offset(offset)
  //       .limit(limit)
  //       .findAllSync();
  // });