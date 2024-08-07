// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:azari/src/logging/logging.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/impl/conventers/danbooru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/booru/strip_html.dart";
import "package:azari/src/net/cloudflare_exception.dart";
import "package:dio/dio.dart";
import "package:logging/logging.dart";

class Danbooru implements BooruAPI {
  const Danbooru(
    this.client, {
    this.booru = Booru.danbooru,
  });

  static final _log = Logger("Danbooru API");

  final Dio client;

  @override
  final Booru booru;

  @override
  bool get wouldBecomeStale => false;

  @override
  Future<int> totalPosts(String tags, SafeMode safeMode) async {
    final resp = await _commonPosts(
      "",
      null,
      safeMode: SafeMode.none,
      page: 0,
      limit: 1,
    );

    return resp.$1.firstOrNull?.id ?? 0;
  }

  @override
  Future<Iterable<String>> notes(int postId) async {
    final resp = await client.getUriLog<List<Map<String, dynamic>>>(
      Uri.https(booru.url, "/notes.json", {
        "search[post_id]": postId.toString(),
      }),
      LogReq(LogReq.notes(postId), _log),
    );

    return (resp.data!).map((e) => stripHtml(e["body"] as String));
  }

  @override
  Future<List<BooruTag>> searchTag(
    String tag, [
    BooruTagSorting sorting = BooruTagSorting.count,
    int limit = 30,
  ]) async {
    if (tag.isEmpty) {
      return const [];
    }

    final resp = await client.getUriLog<List<dynamic>>(
      Uri.https(booru.url, "/tags.json", {
        "search[name_matches]": "$tag*",
        "search[order]": sorting == BooruTagSorting.count ? "count" : "name",
        "limit": limit.toString(),
      }),
      LogReq(LogReq.completeTag(tag), _log),
    );

    return resp.data!
        .map(
          (e) => BooruTag(
            (e as Map<String, dynamic>)["name"] as String,
            e["post_count"] as int,
          ),
        )
        .toList();
  }

  @override
  Future<Post> singlePost(int id) async {
    final resp = await client.getUriLog<dynamic>(
      Uri.https(booru.url, "/posts/$id.json"),
      LogReq(LogReq.singlePost(id, tags: "", safeMode: SafeMode.none), _log),
    );

    if (resp.data == null) {
      throw "no post";
    }

    return fromList([resp.data])[0];
  }

  @override
  Future<(List<Post>, int?)> page(
    int i,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode, [
    int? limit,
  ]) =>
      _commonPosts(
        tags,
        excludedTags,
        page: i,
        safeMode: safeMode,
        limit: limit,
      );

  @override
  Future<(List<Post>, int?)> fromPost(
    int postId,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode, [
    int? limit,
  ]) =>
      _commonPosts(
        tags,
        excludedTags,
        postid: postId,
        safeMode: safeMode,
        limit: limit,
      );

  Future<(List<Post>, int?)> _commonPosts(
    String tags,
    BooruTagging? excludedTags, {
    int? postid,
    int? page,
    required SafeMode safeMode,
    int? limit,
  }) async {
    if (postid == null && page == null) {
      throw "postid or page should be set";
    } else if (postid != null && page != null) {
      throw "only one should be set";
    }

    String safeModeS() => switch (safeMode) {
          SafeMode.normal => "rating:g",
          SafeMode.none => "",
          SafeMode.relaxed => "rating:g,s",
        };

    final query = <String, dynamic>{
      "limit": limit?.toString() ?? numberOfElementsPerRefresh().toString(),
      "format": "json",

      /// anonymous api calls to danbooru are limited by two tags per search req
      "post[tags]": "${safeModeS()} ${tags.split(" ").take(2).join(" ")}",
    };

    if (postid != null) {
      query["page"] = "b$postid";
    }

    if (page != null) {
      query["page"] = page.toString();
    }

    try {
      final resp = await client.getUriLog<List<dynamic>>(
        Uri.https(booru.url, "/posts.json", query),
        LogReq(
          postid != null
              ? LogReq.singlePost(postid, tags: tags, safeMode: safeMode)
              : LogReq.page(page!, tags: tags, safeMode: safeMode),
          _log,
        ),
      );

      return excludedTags == null
          ? (fromList(resp.data!), null)
          : _skipExcluded(fromList(resp.data!), excludedTags);
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

(List<Post>, int?) _skipExcluded(List<Post> posts, BooruTagging excludedTags) {
  final exclude = excludedTags.get(-1);

  if (exclude.isEmpty) {
    return (posts, null);
  }

  int? currentSkipped;

  posts.removeWhere((e) {
    for (final tag in exclude) {
      if (e.tags.contains(tag.tag)) {
        currentSkipped = e.id;
        return true;
      }
    }

    return false;
  });

  return (posts, currentSkipped);
}
