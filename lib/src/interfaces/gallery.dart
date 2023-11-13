// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid/data_loaders/cell_loader.dart';
import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';

import '../db/schemas/system_gallery_directory.dart';
import '../db/schemas/system_gallery_directory_file.dart';

enum GalleryFilesKind {
  primary,
  secondary;

  BackgroundCellLoader<SystemGalleryDirectoryFile, int> fromCache() =>
      this == primary
          ? BackgroundCellLoader.filesPrimary()
          : BackgroundCellLoader.filesSecondary();
}

abstract class GalleryAPIFiles {
  bool get isTrash;
  bool get isFavorites;

  BackgroundDataLoader<SystemGalleryDirectoryFile, int> get loader;
}

abstract class GalleryAPIDirectories {
  GalleryAPIFiles joinedDir(List<String> bucketIds, GalleryFilesKind kind);
  GalleryAPIFiles trash(GalleryFilesKind kind);
  GalleryAPIFiles favorites(GalleryFilesKind kind);

  void addBlacklisted(List<BlacklistedDirectory> bucketIds);

  BackgroundDataLoader<SystemGalleryDirectory, int> get loader;

  GalleryAPIFiles files(SystemGalleryDirectory d, GalleryFilesKind kind);
}


  // FilterInterface<SystemGalleryDirectory> get filter;
  // Isar get db;

  // void setRefreshGridCallback(void Function() callback);
  // void setTemporarySet(void Function(int, bool) callback);
  // void setRefreshingStatusCallback(
  // void Function(int i, bool inRefresh, bool empty) callback);

  // void setPassFilter(
  //     (Iterable<SystemGalleryDirectory>, dynamic) Function(
  //             Iterable<SystemGalleryDirectory>, dynamic, bool)?
  //         filter);



  // FilterInterface<SystemGalleryDirectoryFile> get filter;
  // Isar get db;

  // bool get supportsDirectRefresh;

  // void setRefreshGridCallback(void Function() callback);
  // Future<void> loadNextThumbnails(void Function() callback);
  // void setRefreshingStatusCallback(
  //     void Function(int i, bool inRefresh, bool empty) callback);
  // void setPassFilter(
  //     (Iterable<SystemGalleryDirectoryFile>, dynamic) Function(
  //             Iterable<SystemGalleryDirectoryFile> cells,
  //             dynamic data,
  //             bool end)
  //         f);