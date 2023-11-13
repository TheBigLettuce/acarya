// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/interfaces/gallery.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/widgets/grid/data_loaders/dummy_loader.dart';
import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';

class DummyGallery implements GalleryPlug {
  @override
  GalleryAPIDirectories galleryApi(
      {bool? temporaryDb, bool setCurrentApi = true}) {
    return const _DummyDirectories();
  }
}

class _DummyDirectories implements GalleryAPIDirectories {
  @override
  GalleryAPIFiles files(SystemGalleryDirectory d, _) {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles favorites(_) {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles trash(_) {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles joinedDir(List<String> bucketIds, _) {
    throw UnimplementedError();
  }

  @override
  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {}

  @override
  BackgroundDataLoader<SystemGalleryDirectory, int> get loader =>
      const DummyBackgroundLoader();

  const _DummyDirectories();
}
