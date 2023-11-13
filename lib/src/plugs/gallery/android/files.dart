// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'directories.dart';

class AndroidGalleryFiles implements GalleryAPIFiles {
  @override
  final bool isTrash;
  @override
  final bool isFavorites;

  final String name;

  @override
  final BackgroundCellLoader<SystemGalleryDirectoryFile, int> loader;

  const AndroidGalleryFiles(
    this.loader, {
    required this.name,
    this.isTrash = false,
    this.isFavorites = false,
  });
}

 //  =
  //     BackgroundCellLoader(
  //   (db, idx) => db.systemGalleryDirectoryFiles.get(idx),
  //   DbsOpen.androidGalleryFiles(),
  //   [SystemGalleryDirectoryFileSchema],
  //   makeState: (loader) => CellLoaderStateController(loader),
  //   makeTransformer: null,
  // );

  // final Isar db;

  // void Function() unsetCurrentImages;
  // void Function(int i, bool inRefresh, bool empty)? callback;
  // void Function()? refreshGrid;

    // getElems: (offset, limit, s, sort, mode) {
          //   if (sort == SortingMode.size) {
          //     return db.systemGalleryDirectoryFiles
          //         .filter()
          //         .nameContains(s, caseSensitive: false)
          //         .sortBySizeDesc()
          //         .offset(offset)
          //         .limit(limit)
          //         .findAllSync();
          //   }

          //   // if (mode == FilteringMode.same) {
          //   //   return db.systemGalleryDirectoryFiles
          //   //       .where()
          //   //       .offset(offset)
          //   //       .limit(limit)
          //   //       .findAllSync();
          //   // }

          //   if (s.isEmpty) {
          //     return db.systemGalleryDirectoryFiles
          //         .where()
          //         .sortByLastModifiedDesc()
          //         .offset(offset)
          //         .limit(limit)
          //         .findAllSync();
          //   }

          //   return db.systemGalleryDirectoryFiles
          //       .filter()
          //       .nameContains(s, caseSensitive: false)
          //       .sortByLastModifiedDesc()
          //       .offset(offset)
          //       .limit(limit)
          //       .findAllSync();
          // }

// @override
  // Future<int> refresh() {
  //   try {
  //     db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

  //     if (isTrash) {
  //       PlatformFunctions.refreshTrashed();
  //     } else if (isFavorites) {
  //       PlatformFunctions.refreshFavorites(Dbs.g.blacklisted.favoriteMedias
  //           .where()
  //           .findAllSync()
  //           .map((e) => e.id)
  //           .toList());
  //     } else {
  //       PlatformFunctions.refreshFilesMultiple(directories);
  //     }
  //   } catch (e, trace) {
  //     log("android gallery",
  //         level: Level.SEVERE.value, error: e, stackTrace: trace);
  //   }

  //   return Future.value(db.systemGalleryDirectoryFiles.countSync());
  // }

// @override
// void close() {
  // loader.dispose();
  // filter.dispose();
  // db.close(deleteFromDisk: true);
  // callback = null;
  // refreshGrid = null;

  // unsetCurrentImages();
// }

  // @override
  // Future<int> refresh() {
  //   try {
  //     db.writeTxnSync(() => db.systemGalleryDirectoryFiles.clearSync());

  //     if (isTrash) {
  //       PlatformFunctions.refreshTrashed();
  //     } else if (isFavorites) {
  //       PlatformFunctions.refreshFavorites(Dbs.g.blacklisted.favoriteMedias
  //           .where()
  //           .findAllSync()
  //           .map((e) => e.id)
  //           .toList());
  //     } else {
  //       PlatformFunctions.refreshFiles(_bucketId);
  //     }
  //   } catch (e, trace) {
  //     log("android gallery",
  //         level: Level.SEVERE.value, error: e, stackTrace: trace);
  //   }

  //   return Future.value(db.systemGalleryDirectoryFiles.countSync());
  // }

// Iterable<SystemGalleryDirectoryFile> Function(
//         int, int, String, SortingMode, FilteringMode)
//     defaultGetElemsFiles(Isar db) {
//   return (offset, limit, s, sort, _) {
//     if (sort == SortingMode.size) {
//       return db.systemGalleryDirectoryFiles
//           .filter()
//           .nameContains(s, caseSensitive: false)
//           .sortBySizeDesc()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     if (s.isEmpty) {
//       return db.systemGalleryDirectoryFiles
//           .where()
//           .offset(offset)
//           .limit(limit)
//           .findAllSync();
//     }

//     return db.systemGalleryDirectoryFiles
//         .filter()
//         .nameContains(s, caseSensitive: false)
//         .offset(offset)
//         .limit(limit)
//         .findAllSync();
//   };
// }
