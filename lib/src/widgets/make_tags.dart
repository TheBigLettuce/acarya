// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru_tagging.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:gallery/src/pages/more/settings/radio_dialog.dart';
import 'package:gallery/src/pages/more/settings/settings_label.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/tags/post_tags.dart';
import 'load_tags.dart';
import 'menu_wrapper.dart';
import 'notifiers/filter.dart';
import 'notifiers/filter_value.dart';

PopupMenuItem launchGridSafeModeItem(
  BuildContext context,
  String tag,
  void Function(BuildContext, String, [SafeMode?]) launchGrid,
) =>
    PopupMenuItem(
      onTap: () {
        radioDialog<SafeMode>(
          context,
          SafeMode.values.map((e) => (e, e.translatedString(context))),
          Settings.fromDb().safeMode,
          (value) => launchGrid(context, tag, value),
          title: AppLocalizations.of(context)!.chooseSafeMode,
        );
      },
      child: Text(AppLocalizations.of(context)!.launchWithSafeMode),
    );

Iterable<Widget> makeTags(
  BuildContext context,
  List<String> tags,
  String filename, {
  required List<String> pinnedTags,
  void Function(BuildContext, String, [SafeMode?])? launchGrid,
  BooruTagging? excluded,
}) {
  if (tags.isEmpty) {
    if (filename.isEmpty) {
      return [Container()];
    }
    DisassembleResult? res;
    try {
      res = PostTags.g.dissassembleFilename(filename);
    } catch (_) {}

    return [
      LoadTags(
        filename: filename,
        res: res,
      )
    ];
  }
  final value = FilterValueNotifier.maybeOf(context).trim();
  final data = FilterNotifier.maybeOf(context);

  List<PopupMenuItem> makeItems(String tag) {
    final t = Tag.string(tag: tag);

    return [
      if (excluded != null)
        PopupMenuItem(
          onTap: () {
            if (excluded.exists(t)) {
              excluded.delete(t);
            } else {
              excluded.add(t);
            }
          },
          child: Text(excluded.exists(t)
              ? AppLocalizations.of(context)!.removeFromExcluded
              : AppLocalizations.of(context)!.addToExcluded),
        ),
      if (launchGrid != null)
        launchGridSafeModeItem(
          context,
          tag,
          launchGrid,
        ),
      PopupMenuItem(
        onTap: () {
          if (PinnedTag.isPinned(tag)) {
            PinnedTag.remove(tag);
          } else {
            PinnedTag.add(tag);
          }

          ImageViewInfoTilesRefreshNotifier.refreshOf(context);
        },
        child: Text(
          PinnedTag.isPinned(tag)
              ? AppLocalizations.of(context)!.unpinTag
              : AppLocalizations.of(context)!.pinTag,
        ),
      ),
    ];
  }

  final List<String> filteredTags;
  if (data != null && value.isNotEmpty) {
    filteredTags = tags.where((element) => element.contains(value)).toList();
  } else {
    filteredTags = tags;
  }

  Widget makeTile(String e, bool pinned) => MenuWrapper(
        title: e,
        items: makeItems(e),
        child: ListTile(
          trailing:
              pinned ? const Icon(Icons.push_pin_rounded, size: 18) : null,
          title: Text(e),
          onTap: launchGrid == null
              ? null
              : () {
                  launchGrid(context, e);
                },
        ),
      );

  final tiles = [
    ...pinnedTags.map((e) => makeTile(e, true)),
    ...filteredTags.map((e) => makeTile(e, false)),
  ];

  return [
    SettingsLabel(AppLocalizations.of(context)!.tagsInfoPage,
        Theme.of(context).textTheme.titleSmall!),
    ...ListTile.divideTiles(context: context, tiles: tiles)
  ];
}
