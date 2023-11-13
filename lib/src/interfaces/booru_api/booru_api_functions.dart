// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';

import '../../db/schemas/post.dart';

/// Booru API functions which do not require any state.
abstract class BooruAPIFunctions {
  /// Get a single post by it's id.
  /// This is used in many places, like tags and single post loading in the "Tags" page.
  Future<Post> singlePost(Dio client, int id);

  /// Get the post's notes.
  /// Usually used for translations.
  Future<Iterable<String>> notes(Dio client, int postId);

  /// Tag completition, this shouldn't present more than 10 at a time.
  Future<List<String>> completeTag(Dio client, String tag);

  /// Constructs a link to the post to be loaded in the browser, outside the app.
  Uri browserLink(int id);
}
