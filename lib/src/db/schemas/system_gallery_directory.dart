// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/widgets/grid/cell/cell_data.dart';
import 'package:isar/isar.dart';

import '../../interfaces/cell.dart';
import '../../interfaces/contentable.dart';
import 'system_gallery_directory_file.dart';

part 'system_gallery_directory.g.dart';

@immutable
@collection
class SystemGalleryDirectory implements Cell {
  @Id()
  final int isarId;

  final int thumbFileId;
  @Index(unique: true, hash: true)
  final String bucketId;

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @Index()
  final String name;

  final String relativeLoc;
  final String volumeName;

  @Index()
  final int lastModified;

  @Index()
  final String tag;

  const SystemGalleryDirectory(
      {required this.isarId,
      required this.bucketId,
      required this.name,
      required this.tag,
      required this.volumeName,
      required this.relativeLoc,
      required this.lastModified,
      required this.thumbFileId});

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  List<Widget>? addInfo(
          BuildContext context, dynamic extra, AddInfoColorData colors) =>
      null;

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay(BuildContext context) => const EmptyContent();

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList, {BuildContext? context}) {
    return CellData(
        thumb: ThumbnailProvider(thumbFileId), name: name, stickers: []);
  }

  static SystemGalleryDirectory decode(Object result, int id) {
    result as List<Object?>;

    final bucketId = result[1]! as String;

    return SystemGalleryDirectory(
      isarId: id,
      tag: "",
      thumbFileId: result[0]! as int,
      bucketId: bucketId,
      name: result[2]! as String,
      relativeLoc: result[3]! as String,
      volumeName: result[4]! as String,
      lastModified: result[5]! as int,
    );
  }
}
