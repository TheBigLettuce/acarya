// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/pages/tags.dart';
import 'package:gallery/src/pages/downloads.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import '../../../main.dart';
import '../../booru/interface.dart';
import '../../db/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/settings.dart' as widget;

const int kBooruGridDrawerIndex = 0;
const int kGalleryDrawerIndex = 1;
const int kTagsDrawerIndex = 2;
const int kDownloadsDrawerIndex = 3;
const int kSettingsDrawerIndex = 4;
const int kComeFromRandom = -1;

Widget azariIcon(BuildContext context, {Color? color}) => GestureDetector(
      onTap: () {},
      child: Icon(
        const IconData(0x963F),
        color: color,
      ),
    ); // 阿

List<NavigationDrawerDestination> destinations(BuildContext context,
    {Booru? overrideBooru}) {
  final primaryColor = Theme.of(context).colorScheme.primary;

  return [
    NavigationDrawerDestination(
        icon: const Icon(Icons.image),
        selectedIcon: Icon(
          Icons.image,
          color: primaryColor,
        ),
        label: Text(overrideBooru?.string ??
            settingsIsar().settings.getSync(0)!.selectedBooru.string)),
    NavigationDrawerDestination(
        icon: const Icon(Icons.photo_album),
        selectedIcon: Icon(
          Icons.photo_album,
          color: primaryColor,
        ),
        label: Text(AppLocalizations.of(context)!.galleryLabel)),
    NavigationDrawerDestination(
      icon: const Icon(Icons.tag),
      selectedIcon: Icon(
        Icons.tag,
        color: primaryColor,
      ),
      label: Text(AppLocalizations.of(context)!.tagsLabel),
    ),
    NavigationDrawerDestination(
        icon: settingsIsar().files.countSync() != 0
            ? const Badge(
                child: Icon(Icons.download),
              )
            : const Icon(Icons.download),
        selectedIcon: Icon(
          Icons.download,
          color: primaryColor,
        ),
        label: Text(AppLocalizations.of(context)!.downloadsLabel)),
  ];
}

void selectDestination(BuildContext context, int from, int selectedIndex) =>
    switch (selectedIndex) {
      kBooruGridDrawerIndex => {
          if (from != kBooruGridDrawerIndex)
            {
              Navigator.popUntil(context, ModalRoute.withName("/senitel")),
              Navigator.pop(context),
            }
        },
      kTagsDrawerIndex => {
          if (from == kBooruGridDrawerIndex)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kTagsDrawerIndex)
            {
              if (from == kGalleryDrawerIndex)
                {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchBooru(
                          grids: getTab(),
                          popSenitel: false,
                          fromGallery: true,
                        ),
                      ))
                }
              else
                {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchBooru(
                          grids: getTab(),
                          popSenitel: true,
                          fromGallery: false,
                        ),
                      ),
                      ModalRoute.withName("/senitel"))
                }
            }
        },
      kDownloadsDrawerIndex => {
          if (from == kBooruGridDrawerIndex || from == kComeFromRandom)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kDownloadsDrawerIndex)
            {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Downloads(),
                  ),
                  ModalRoute.withName("/senitel"))
            }
        },
      kSettingsDrawerIndex => {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const widget.Settings()))
        },
      kGalleryDrawerIndex => {
          if (Platform.isAndroid)
            {
              if (from == kBooruGridDrawerIndex)
                {
                  Navigator.pushNamed(context, "/senitel"),
                },
              if (from != kGalleryDrawerIndex)
                {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AndroidDirectories()),
                      ModalRoute.withName("/senitel"))
                }
            },
        },
      int() => throw "unknown value"
    };

Widget endDrawerHeading(
        BuildContext context, String headline, GlobalKey<ScaffoldState> k,
        {Color? titleColor, Color? backroundColor}) =>
    SliverAppBar(
      expandedHeight: 152,
      collapsedHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: backroundColor,
      actions: [Container()],
      pinned: true,
      leading: BackButton(
        onPressed: () {
          k.currentState?.closeEndDrawer();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
          title: Text(
        headline,
        style: TextStyle(color: titleColor),
      )),
    );

Widget? makeEndDrawerSettings(
    BuildContext context, GlobalKey<ScaffoldState> key) {
  if (Platform.isAndroid || Platform.isIOS) {
    return null;
  }

  return Drawer(
      child: CustomScrollView(
    slivers: [
      endDrawerHeading(
          context, AppLocalizations.of(context)!.settingsPageName, key),
      widget.SettingsList(sliver: true, scaffoldKey: key)
    ],
  ));
}

Widget? makeDrawer(BuildContext context, int selectedIndex,
    {void Function(int route, void Function() original)? overrideChooseRoute,
    Booru? overrideBooru}) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return null;
  }
  AnimationController? iconController;

  return NavigationDrawer(
    selectedIndex: selectedIndex,
    onDestinationSelected: (value) {
      if (selectedIndex == kBooruGridDrawerIndex) {
        Navigator.pop(context);
      }

      if (overrideChooseRoute != null) {
        overrideChooseRoute(
            value, () => selectDestination(context, selectedIndex, value));
      } else {
        selectDestination(context, selectedIndex, value);
      }
    },
    children: [
      DrawerHeader(
          child: Center(
        child: GestureDetector(
          onTap: () {
            if (iconController != null) {
              iconController!.forward(from: 0);
            }
          },
          child:
              azariIcon(context, color: Theme.of(context).colorScheme.primary),
        ).animate(
            onInit: (controller) => iconController = controller,
            effects: [ShakeEffect(duration: 700.milliseconds, hz: 6)]),
      )),
      ...destinations(context, overrideBooru: overrideBooru),
      const Divider(),
      NavigationDrawerDestination(
          icon: const Icon(Icons.settings),
          label: Text(AppLocalizations.of(context)!.settingsLabel))
    ],
  );
}
