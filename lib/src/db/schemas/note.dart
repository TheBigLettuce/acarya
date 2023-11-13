// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import 'package:gallery/src/db/schemas/tags.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru_api/booru.dart';
import 'package:gallery/src/widgets/notifiers/network_configuration.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/interfaces/contentable.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/grid/cell/cell_data.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../interfaces/cell.dart';
import '../../plugs/platform_channel.dart';
import 'settings.dart';

part 'note.g.dart';

@immutable
@collection
class NoteBooru extends NoteBase implements Cell {
  @override
  Key uniqueKey() => ValueKey((postId, booru));

  @Index(unique: true, composite: ["booru"])
  final int postId;
  final Booru booru;

  @Id()
  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  static NoteBooru? get(int postId, Booru booru) {
    return Dbs.g.blacklisted.noteBoorus
        .where()
        .postIdEqualTo(postId)
        .booruEqualTo(booru)
        .findFirst();
  }

  static void reorder(
      {required int postId,
      required Booru booru,
      required int from,
      required int to}) {
    final n = get(postId, booru);
    if (n == null || from == to) {
      return;
    }

    final newText = n.text.toList();
    final e1 = newText[from];
    newText.removeAt(from);
    if (to == 0) {
      newText.insert(0, e1);
    } else {
      newText.insert(to - 1, e1);
    }

    Dbs.g.blacklisted.write((i) => i.noteBoorus.put(NoteBooru(newText, n.time,
        postId: postId,
        booru: booru,
        backgroundColor: n.backgroundColor,
        textColor: n.textColor,
        fileUrl: n.fileUrl,
        sampleUrl: n.sampleUrl,
        previewUrl: n.previewUrl)));
  }

  static bool add(int pid, Booru booru,
      {required String text,
      required String fileUrl,
      required String sampleUrl,
      required Color? backgroundColor,
      required Color? textColor,
      required previewUrl}) {
    final n = get(pid, booru);

    Dbs.g.blacklisted.write((i) => i.noteBoorus.put(NoteBooru(
        [...n?.text ?? [], text], DateTime.now(),
        postId: pid,
        booru: booru,
        backgroundColor: backgroundColor?.value,
        textColor: textColor?.value,
        fileUrl: fileUrl,
        sampleUrl: sampleUrl,
        previewUrl: previewUrl)));

    return n == null;
  }

  static void replace(int pid, Booru booru, int idx, String newText) {
    final n = get(pid, booru);
    if (n == null) {
      return;
    }
    final t = n.text.toList();
    t[idx] = newText;

    Dbs.g.blacklisted.write((i) => i.noteBoorus.put(NoteBooru(t, n.time,
        postId: n.postId,
        booru: n.booru,
        backgroundColor: n.backgroundColor,
        textColor: n.textColor,
        fileUrl: n.fileUrl,
        sampleUrl: n.sampleUrl,
        previewUrl: n.previewUrl)));
  }

  static bool remove(int pid, Booru booru, int indx) {
    final n = get(pid, booru);
    if (n == null) {
      return false;
    }
    final t = n.text.toList()..removeAt(indx);
    return Dbs.g.blacklisted.write((i) {
      if (t.isEmpty) {
        return i.noteBoorus
            .where()
            .postIdEqualTo(pid)
            .booruEqualTo(booru)
            .deleteFirst();
      } else {
        i.noteBoorus.put(NoteBooru(t, DateTime.now(),
            postId: pid,
            booru: booru,
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl));

        return false;
      }
    });
  }

  static bool hasNotes(int pid, Booru booru) {
    return get(pid, booru) != null;
  }

  static List<NoteBooru> load() {
    return Dbs.g.blacklisted.noteBoorus.where().findAll();
  }

  List<String> currentText() {
    return get(postId, booru)!.text;
  }

  static NoteInterface<NoteBooru> interfaceSelf(void Function() onDelete) {
    return NoteInterface(
      reorder: (cell, from, to) {
        reorder(booru: cell.booru, postId: cell.postId, from: from, to: to);
      },
      addNote: (text, cell, backgroundColor, textColor) {
        if (NoteBooru.add(cell.postId, cell.booru,
            text: text,
            backgroundColor: backgroundColor,
            textColor: textColor,
            fileUrl: cell.fileUrl,
            sampleUrl: cell.sampleUrl,
            previewUrl: cell.previewUrl)) {
          onDelete();
        }
      },
      delete: (cell, indx) {
        if (NoteBooru.remove(cell.postId, cell.booru, indx)) {
          onDelete();
        }
      },
      load: (cell) {
        return get(cell.postId, cell.booru);
      },
      replace: (cell, indx, newText) {
        NoteBooru.replace(cell.postId, cell.booru, indx, newText);
      },
    );
  }

  static NoteInterface<T> interface<T extends PostBase>(
      void Function(void Function()) setState) {
    return NoteInterface(
      reorder: (cell, from, to) {
        reorder(
            booru: Booru.fromPrefix(cell.prefix)!,
            postId: cell.postId,
            from: from,
            to: to);
      },
      addNote: (text, cell, backgroundColor, textColor) {
        NoteBooru.add(
          cell.postId,
          Booru.fromPrefix(cell.prefix)!,
          text: text,
          backgroundColor: backgroundColor,
          textColor: textColor,
          fileUrl: cell.fileUrl,
          sampleUrl: cell.sampleUrl,
          previewUrl: cell.previewUrl,
        );
        try {
          setState(() {});
        } catch (_) {}
      },
      replace: (cell, indx, newText) {
        NoteBooru.replace(
            cell.postId, Booru.fromPrefix(cell.prefix)!, indx, newText);
      },
      delete: (cell, indx) {
        NoteBooru.remove(cell.postId, Booru.fromPrefix(cell.prefix)!, indx);
        try {
          setState(() {});
        } catch (_) {}
      },
      load: (cell) {
        return get(cell.postId, Booru.fromPrefix(cell.prefix)!);
      },
    );
  }

  const NoteBooru(super.text, super.time,
      {required this.postId,
      required this.booru,
      required super.backgroundColor,
      required super.textColor,
      required this.fileUrl,
      required this.sampleUrl,
      required this.previewUrl});

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.public),
        onPressed: () {
          launchUrl(booru.functions().browserLink(postId),
              mode: LaunchMode.externalApplication);
        },
      ),
      if (Platform.isAndroid)
        GestureDetector(
          onLongPress: () {
            PostBase.showQr(context, booru.prefix, postId);
          },
          child: IconButton(
              onPressed: () {
                PlatformFunctions.shareMedia(fileUrl, url: true);
              },
              icon: const Icon(Icons.share)),
        )
      else
        IconButton(
            onPressed: () {
              PostBase.showQr(context, booru.prefix, postId);
            },
            icon: const Icon(Icons.qr_code_rounded))
    ];
  }

  @override
  List<Widget>? addInfo(BuildContext context, extra, AddInfoColorData colors) {
    return null;
  }

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    return null;
  }

  @override
  String alias(bool isList) {
    return postId.toString();
  }

  @override
  Contentable fileDisplay(BuildContext context) {
    String url = switch (Settings.fromDb().quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    var type = lookupMimeType(url);
    if (type == null) {
      return const EmptyContent();
    }

    var typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      ImageProvider provider;
      try {
        provider = NetworkImage(url,
            headers: NetworkConfigurationProvider.of(context).asHeaders());
      } catch (e) {
        provider = MemoryImage(kTransparentImage);
      }

      return typeHalf[1] == "gif" ? NetGif(provider) : NetImage(provider);
    } else if (typeHalf[0] == "video") {
      return NetVideo(url);
    } else {
      return const EmptyContent();
    }
  }

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    return CellData(
        thumb: CachedNetworkImageProvider(previewUrl,
            headers: NetworkConfigurationProvider.of(context).asHeaders()),
        name: postId.toString(),
        stickers: const []);
  }
}

class NoteBase {
  // @Index(caseSensitive: false, type: IndexType.hash)
  final List<String> text;
  @Index()
  final DateTime time;

  final int? backgroundColor;
  final int? textColor;

  const NoteBase(this.text, this.time,
      {required this.backgroundColor, required this.textColor});
}
