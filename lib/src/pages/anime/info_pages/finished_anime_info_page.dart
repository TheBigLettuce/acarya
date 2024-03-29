// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/anime/watched_anime_entry.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_app_bar.dart';
import 'package:gallery/src/pages/anime/info_base/anime_info_theme.dart';
import 'package:gallery/src/pages/anime/info_base/background_image/background_image.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_info_body.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_panel.dart';
import 'package:gallery/src/pages/anime/info_base/card_panel/card_shell.dart';
import 'package:gallery/src/pages/anime/info_base/always_loading_anime_mixin.dart';
import 'package:gallery/src/pages/anime/info_base/refresh_entry_icon.dart';
import 'package:gallery/src/widgets/skeletons/settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FinishedAnimeInfoPage extends StatefulWidget {
  final WatchedAnimeEntry entry;

  const FinishedAnimeInfoPage({super.key, required this.entry});

  @override
  State<FinishedAnimeInfoPage> createState() => _FinishedAnimeInfoPageState();
}

class _FinishedAnimeInfoPageState extends State<FinishedAnimeInfoPage>
    with AlwaysLoadingAnimeMixin {
  late final StreamSubscription<WatchedAnimeEntry?> watcher;
  late WatchedAnimeEntry entry = widget.entry;
  final state = SkeletonState();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    watcher = entry.watch((e) {
      if (e == null) {
        Navigator.pop(context);
        return;
      }

      entry = e;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();
    scrollController.dispose();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.background;

    Widget body() => SettingsSkeleton(
          AppLocalizations.of(context)!.finishedTab,
          state,
          bottomAppBar: BottomAppBar(
            child: Row(
              children: [
                ...CardPanel.defaultButtons(
                  context,
                  entry,
                  isWatching: false,
                  inBacklog: false,
                  watched: true,
                ),
                IconButton(
                    onPressed: () {
                      WatchedAnimeEntry.delete(entry.id, entry.site);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.removeFromWatched),
                        action: SnackBarAction(
                            label: AppLocalizations.of(context)!.undoLabel,
                            onPressed: () {
                              WatchedAnimeEntry.read(entry);
                            }),
                      ));
                    },
                    icon: const Icon(Icons.close_rounded))
              ],
            ),
          ),
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimeInfoAppBar(
                cell: entry,
                scrollController: scrollController,
                appBarActions: [
                  RefreshEntryIcon(entry, (e) => entry.copySuper(e).save())
                ],
              )),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom),
              child: Stack(children: [
                BackgroundImage(image: entry.thumbnail()!),
                Column(
                  children: [
                    CardShell(
                      title: widget.entry.title,
                      titleEnglish: widget.entry.titleEnglish,
                      titleJapanese: widget.entry.titleJapanese,
                      titleSynonyms: widget.entry.titleSynonyms,
                      safeMode: widget.entry.explicit,
                      viewPadding: MediaQuery.viewPaddingOf(context),
                      info: [
                        ...CardPanel.defaultInfo(context, entry),
                      ],
                    ),
                    AnimeInfoBody(
                      overlayColor: overlayColor,
                      entry: entry,
                      viewPadding: MediaQuery.viewPaddingOf(context),
                    ),
                  ],
                )
              ]),
            ),
          ),
        );

    return AnimeInfoTheme(
      mode: entry.explicit,
      overlayColor: overlayColor,
      child: WrapFutureRestartable(
        builder: (context, value) {
          return body();
        },
        newStatus: () => maybeFetchInfo(entry).then((value) {
          entry.copySuper(value).save();

          return value;
        }),
      ),
    );
  }
}
