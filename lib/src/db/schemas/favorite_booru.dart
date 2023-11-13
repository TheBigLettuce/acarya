// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/post.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

part 'favorite_booru.g.dart';

@immutable
@collection
class FavoriteBooru extends PostBase {
  @Index()
  final String group;

  FavoriteBooru withGroup(String group) {
    return FavoriteBooru(
        isarId: isarId,
        height: height,
        postId: postId,
        md5: md5,
        tags: tags,
        width: width,
        fileUrl: fileUrl,
        prefix: prefix,
        previewUrl: previewUrl,
        sampleUrl: sampleUrl,
        ext: ext,
        group: group,
        sourceUrl: sourceUrl,
        rating: rating,
        score: score,
        createdAt: createdAt);
  }

  const FavoriteBooru(
      {required super.isarId,
      required super.height,
      required super.postId,
      required super.md5,
      required super.tags,
      required super.width,
      required super.fileUrl,
      required super.prefix,
      required super.previewUrl,
      required super.sampleUrl,
      required super.ext,
      required this.group,
      required super.sourceUrl,
      required super.rating,
      required super.score,
      required super.createdAt});
}
