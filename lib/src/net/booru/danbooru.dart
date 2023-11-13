// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/interfaces/booru_api/booru.dart';
import 'package:gallery/src/interfaces/booru_api/booru_api_functions.dart';
import 'package:gallery/src/interfaces/booru_api/strip_html.dart';
import 'package:gallery/src/interfaces/booru_api/unsaveable_cookie_jar.dart';

import '../../db/schemas/settings.dart';
import '../../interfaces/booru_api/booru_api_state.dart';
import '../../interfaces/tags.dart';

List<String> _fromDanbooruTags(List<dynamic> l) =>
    l.map((e) => e["name"] as String).toList();

class DanbooruFunctions implements BooruAPIFunctions {
  final Booru _booru;

  const DanbooruFunctions(this._booru);

  @override
  Uri browserLink(int id) => Uri.https(_booru.url, "/posts/$id");

  @override
  Future<Iterable<String>> notes(Dio client, int postId) async {
    final resp = await client.getUri(Uri.https(_booru.url, "/notes.json", {
      "search[post_id]": postId.toString(),
    }));

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return Future.value(
        (resp.data as List<dynamic>).map((e) => stripHtml(e["body"])));
  }

  @override
  Future<List<String>> completeTag(Dio client, String tag) async {
    final resp = await client.getUri(
      Uri.https(_booru.url, "/tags.json", {
        "search[name_matches]": "$tag*",
        "search[order]": "count",
        "limit": "10",
      }),
    );

    if (resp.statusCode != 200) {
      throw "status code not 200";
    }

    return _fromDanbooruTags(resp.data);
  }

  @override
  Future<Post> singlePost(Dio client, int id) async {
    try {
      final resp =
          await client.getUri(Uri.https(_booru.url, "/posts/$id.json"));

      if (resp.statusCode != 200) {
        throw resp.data["message"];
      }

      if (resp.data == null) {
        throw "no post";
      }

      return (await Danbooru._fromJson([resp.data], null, _booru)).$1[0];
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return Future.error(CloudflareException());
        }
      }
      return Future.error(e);
    }
  }
}

class Danbooru implements BooruAPIState {
  final UnsaveableCookieJar cookieJar;

  @override
  void setCookies(List<Cookie> cookies) {
    cookieJar.replaceDirectly(Uri.parse(booru.url), cookies);
  }

  @override
  BooruAPIFunctions get functions => DanbooruFunctions(booru);

  @override
  final Dio client;

  @override
  final Booru booru;

  @override
  final int? currentPage = null;

  @override
  final bool wouldBecomeStale = false;

  @override
  Future<(List<Post>, int?)> page(int i, String tags, BooruTagging excludedTags,
          {SafeMode? overrideSafeMode}) =>
      _commonPosts(tags, excludedTags,
          page: i, overrideSafeMode: overrideSafeMode);

  @override
  Future<(List<Post>, int?)> fromPost(
          int postId, String tags, BooruTagging excludedTags,
          {SafeMode? overrideSafeMode}) =>
      _commonPosts(tags, excludedTags,
          postid: postId, overrideSafeMode: overrideSafeMode);

  Future<(List<Post>, int?)> _commonPosts(
      String tags, BooruTagging excludedTags,
      {int? postid, int? page, required SafeMode? overrideSafeMode}) async {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    // anonymous api calls to danbooru are limited by two tags per search req
    tags = tags.split(" ").take(2).join(" ");

    String safeModeS() =>
        switch (overrideSafeMode ?? Settings.fromDb().safeMode) {
          SafeMode.normal => "rating:g",
          SafeMode.none => '',
          SafeMode.relaxed => "rating:g,s",
        };

    final query = <String, dynamic>{
      "limit": BooruAPIState.numberOfElementsPerRefresh().toString(),
      "format": "json",
      "post[tags]": "${safeModeS()} $tags",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    try {
      final resp =
          await client.getUri(Uri.https(booru.url, "/posts.json", query));

      if (resp.statusCode != 200) {
        throw "status not ok";
      }

      return _fromJson(resp.data, excludedTags, booru);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          return Future.error(CloudflareException());
        }
      }

      return Future.error(e);
    }
  }

  static Future<(List<Post>, int?)> _fromJson(
      List<dynamic> m, BooruTagging? excludedTags, Booru booru) async {
    final List<Post> list = [];
    int? currentSkipped;
    final exclude = excludedTags?.get();

    outer:
    for (final e in m) {
      try {
        final String tags = e["tag_string"];
        if (exclude != null) {
          for (final tag in exclude) {
            if (tags.contains(tag.tag)) {
              currentSkipped = e["id"];
              continue outer;
            }
          }
        }

        final post = Post(
            isarId: DbsOpen.primaryGridInstance(booru).posts.autoIncrement(),
            height: e["image_height"],
            postId: e["id"],
            score: e["score"],
            sourceUrl: e["source"],
            rating: e["rating"] ?? "?",
            createdAt: DateTime.parse(e["created_at"]),
            md5: e["md5"],
            tags: tags.split(" "),
            width: e["image_width"],
            fileUrl: e["file_url"],
            previewUrl: e["preview_file_url"],
            sampleUrl: e["large_file_url"],
            ext: ".${e["file_ext"]}",
            prefix: booru.prefix);

        list.add(post);
      } catch (_) {
        continue;
      }
    }

    return (List<Post>.unmodifiable(list), currentSkipped);
  }

  @override
  void close() => client.close(force: true);

  Danbooru(this.client, this.cookieJar, {this.booru = Booru.danbooru});
}
