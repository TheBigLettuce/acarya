// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path_util;

import '../plugs/platform_fullscreens.dart';
import 'cell.dart';
import 'data.dart';

String _fileDownloadUrl(String sampleUrl, String originalUrl) {
  if (path_util.extension(originalUrl) == ".zip") {
    return sampleUrl;
  } else {
    return originalUrl;
  }
}

class BooruCell extends Cell {
  String originalUrl;
  //String postNumber;
  String tags;
  String sampleUrl;
  int postId;

  @override
  String alias(bool isList) => isList ? tags : postId.toString();

  @override
  String fileDownloadUrl() => _fileDownloadUrl(sampleUrl, originalUrl);

  @override
  Content fileDisplay() {
    var settings = isar().settings.getSync(0);
    String url;
    if (settings!.quality == DisplayQuality.original) {
      url = originalUrl;
    } else if (settings.quality == DisplayQuality.sample) {
      url = sampleUrl;
    } else {
      throw "invalid display quality";
    }

    var type = lookupMimeType(url);
    if (type == null) {
      return Content("", false);
    }

    var typeHalf = type.split("/")[0];

    if (typeHalf == "image") {
      return Content(typeHalf, false, image: NetworkImage(url));
    } else if (typeHalf == "video") {
      return Content(typeHalf, false, videoPath: url);
    } else {
      return Content(typeHalf, false);
    }
  }

  @override
  CellData getCellData(bool isList) =>
      CellData(thumb: CachedNetworkImageProvider(path), name: alias(isList));

  BooruCell(
      {required int post,
      required super.path,
      required this.originalUrl,
      required this.tags,
      required this.sampleUrl,
      required void Function(String tag) onTagPressed})
      : postId = post,
        super(
            addInfo: (dynamic extra, Color dividerColor, Color foregroundColor,
                Color systemOverlayColor) {
              var downloadUrl = _fileDownloadUrl(sampleUrl, originalUrl);
              List<Widget> list = [
                ListTile(
                  textColor: foregroundColor,
                  title: const Text("Path"),
                  subtitle: Text(downloadUrl),
                  onTap: () => launchUrl(Uri.parse(downloadUrl),
                      mode: LaunchMode.externalApplication),
                ),
                ListTile(
                  textColor: foregroundColor,
                  title: const Text("Tags"),
                )
              ];

              var plug = choosePlatformFullscreenPlug(systemOverlayColor);

              list.addAll(ListTile.divideTiles(
                  color: dividerColor,
                  tiles: tags.split(' ').map((e) => ListTile(
                        textColor: foregroundColor,
                        title: Text(HtmlUnescape().convert(e)),
                        onTap: () {
                          onTagPressed(HtmlUnescape().convert(e));
                          plug.unFullscreen();
                          extra();
                        },
                      ))));

              return [
                ListBody(
                  children: list,
                )
              ];
            },
            addButtons: () => [
                  if (tags.contains("original"))
                    const IconButton(
                      icon: Icon(IconData(79)),
                      onPressed: null,
                    ),
                  IconButton(
                      icon: const Icon(Icons.public),
                      onPressed: () => launchUrl(getBooru().browserLink(post),
                          mode: LaunchMode.externalApplication)),
                ]);
}
