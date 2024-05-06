// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsGalleryDataExt on StatisticsGalleryData {
  void save() => _currentDb.statisticsGallery.add(this);
}

abstract class StatisticsGalleryData {
  const StatisticsGalleryData({
    required this.copied,
    required this.deleted,
    required this.joined,
    required this.moved,
    required this.filesSwiped,
    required this.sameFiltered,
    required this.viewedDirectories,
    required this.viewedFiles,
  });

  final int viewedDirectories;
  final int viewedFiles;
  final int filesSwiped;
  final int joined;
  final int sameFiltered;
  final int deleted;
  final int copied;
  final int moved;

  StatisticsGalleryData add({
    int? viewedDirectories,
    int? viewedFiles,
    int? joined,
    int? filesSwiped,
    int? sameFiltered,
    int? deleted,
    int? copied,
    int? moved,
  });
}

abstract interface class StatisticsGalleryService implements ServiceMarker {
  StatisticsGalleryData get current;

  void add(StatisticsGalleryData data);
}
