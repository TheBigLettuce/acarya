// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
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
import 'package:gallery/src/widgets/notifiers/tag_refresh.dart';

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
          allowSingle: true,
        );
      },
      child: Text(AppLocalizations.of(context)!.launchWithSafeMode),
    );

class DrawerTagsWidget extends StatefulWidget {
  final List<String> tags;
  final String filename;
  final List<String> pinnedTags;
  final void Function(BuildContext, String, [SafeMode?])? launchGrid;
  final BooruTagging? excluded;
  final DisassembleResult? res;
  final bool showLabel;
  final bool showDeleteButton;

  const DrawerTagsWidget(
    this.tags,
    this.filename, {
    super.key,
    required this.pinnedTags,
    this.launchGrid,
    this.excluded,
    this.showLabel = true,
    required this.showDeleteButton,
    required this.res,
  });

  @override
  State<DrawerTagsWidget> createState() => _DrawerTagsWidgetState();
}

class _DrawerTagsWidgetState extends State<DrawerTagsWidget> {
  late final StreamSubscription<void>? _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = widget.excluded?.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher?.cancel();

    super.dispose();
  }

  List<PopupMenuItem> makeItems(BuildContext context, String tag) {
    final t = Tag.string(tag: tag);
    final excluded = widget.excluded;

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
      if (widget.launchGrid != null)
        launchGridSafeModeItem(
          context,
          tag,
          widget.launchGrid!,
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

  Widget makeTile(BuildContext context, String e, bool pinned) => MenuWrapper(
        title: e,
        items: makeItems(context, e),
        child: RawChip(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          avatar: pinned ? const Icon(Icons.push_pin_rounded, size: 18) : null,
          label: Text(
            e,
            style: TextStyle(
              color: widget.excluded != null &&
                      widget.excluded!.exists(Tag.string(tag: e))
                  ? Colors.red
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.9)
                  : null,
            ),
          ),
          onPressed: widget.launchGrid == null
              ? null
              : () {
                  widget.launchGrid!(context, e);
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;
    final filename = widget.filename;
    final res = widget.res;
    final pinnedTags = widget.pinnedTags;
    final showLabel = widget.showLabel;

    if (tags.isEmpty) {
      if (filename.isEmpty) {
        return const SliverPadding(padding: EdgeInsets.zero);
      }

      return res == null
          ? const SliverPadding(padding: EdgeInsets.zero)
          : LoadTags(
              filename: filename,
              res: res,
            );
    }

    final value = FilterValueNotifier.maybeOf(context).trim();
    final data = FilterNotifier.maybeOf(context);

    final Iterable<String> filteredTags;
    if (data != null && value.isNotEmpty) {
      filteredTags = tags.where((element) => element.contains(value));
    } else {
      filteredTags = tags;
    }

    final tiles = pinnedTags
        .map((e) => makeTile(context, e, true))
        .followedBy(filteredTags.map((e) => makeTile(context, e, false)));

    return SliverList.list(
      children: [
        if (showLabel)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SettingsLabel(
                AppLocalizations.of(context)!.tagsInfoPage,
                Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).listTileTheme.textColor,
                    ),
              ),
              if (widget.showDeleteButton)
                IconButton(
                  onPressed: () {
                    final notifier = TagRefreshNotifier.maybeOf(context);
                    PostTags.g.deletePostTags(filename);
                    notifier?.call();
                  },
                  icon: const Icon(Icons.delete),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                )
            ],
          )
        else
          const Padding(padding: EdgeInsets.only(top: 8)),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 16, bottom: 8),
          child: Wrap(
            spacing: 4,
            children: tiles.toList(),
          ),
        )
      ],
    );
  }
}
