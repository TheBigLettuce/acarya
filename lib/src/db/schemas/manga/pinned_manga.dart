// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/manga/compact_manga_data.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:isar/isar.dart';

part 'pinned_manga.g.dart';

@collection
class PinnedManga extends CompactMangaDataBase {
  PinnedManga({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });

  static bool exist(String mangaId, MangaMeta site) {
    return Dbs.g.anime.pinnedMangas.getByMangaIdSiteSync(mangaId, site) != null;
  }

  static List<PinnedManga> getAll(int limit) {
    if (limit.isNegative) {
      return Dbs.g.anime.pinnedMangas.where().findAllSync();
    }

    return Dbs.g.anime.pinnedMangas.where().limit(limit).findAllSync();
  }

  static void addAll(List<PinnedManga> l, [bool saveId = false]) {
    if (l.isEmpty) {
      return;
    }

    if (saveId) {
      Dbs.g.anime.writeTxnSync(
        () => Dbs.g.anime.pinnedMangas.putAllSync(l),
      );

      return;
    }

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.pinnedMangas.putAllByMangaIdSiteSync(l),
    );
  }

  static void deleteAll(List<int> ids) {
    if (ids.isEmpty) {
      return;
    }

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.pinnedMangas.deleteAll(ids),
    );
  }

  static void deleteAllIds(List<(MangaId, MangaMeta)> ids) {
    if (ids.isEmpty) {
      return;
    }

    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.pinnedMangas.deleteAllByMangaIdSiteSync(
        ids.map((e) => e.$1.toString()).toList(),
        ids.map((e) => e.$2).toList(),
      ),
    );
  }

  static void deleteSingle(String mangaId, MangaMeta site) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.pinnedMangas.deleteByMangaIdSiteSync(mangaId, site),
    );
  }

  static StreamSubscription<void> watch(void Function(void) f) {
    return Dbs.g.anime.pinnedMangas.watchLazy().listen(f);
  }
}
