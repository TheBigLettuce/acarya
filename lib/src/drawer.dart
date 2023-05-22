// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/lost_downloads.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'db/isar.dart';

const IconData kAzariIcon = IconData(0x963F);

List<NavigationDrawerDestination> destinations() {
  return [
    NavigationDrawerDestination(
        icon: const Icon(Icons.image),
        label: Text(isar().settings.getSync(0)!.selectedBooru.string)),
    const NavigationDrawerDestination(
      icon: Icon(Icons.tag),
      label: Text("Tags"),
    ),
    NavigationDrawerDestination(
        icon: isar().files.countSync() != 0
            ? const Badge(
                child: Icon(Icons.download),
              )
            : const Icon(Icons.download),
        label: const Text("Downloads")),
  ];
}

void selectDestination(
        BuildContext context, int value, int selectedIndex, bool pushSenitel) =>
    switch (value) {
      0 => {
          if (selectedIndex != 0)
            {
              Navigator.popUntil(context, ModalRoute.withName("/senitel")),
              Navigator.pop(context),
            }
          else
            {Navigator.pop(context)}
        },
      1 => {
          if (pushSenitel)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchBooru(),
              ),
              ModalRoute.withName("/senitel"))
        },
      2 => {
          if (pushSenitel)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LostDownloads(),
              ),
              ModalRoute.withName("/senitel"))
        },
      /*  3 => {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const widget.Settings()))
        },*/
      int() => throw "unknown value"
    };

Widget? makeDrawer(BuildContext context, int selectedIndex, bool pushSenitel) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return null;
  }
  AnimationController? iconController;

  return NavigationDrawer(
    selectedIndex: selectedIndex,
    onDestinationSelected: (value) =>
        selectDestination(context, value, selectedIndex, pushSenitel),
    children: [
      DrawerHeader(
          child: Center(
        child: GestureDetector(
          onTap: () {
            if (iconController != null) {
              iconController!.forward(from: 0);
            }
          },
          child: const Icon(
            kAzariIcon,
          ),
        ).animate(
            onInit: (controller) => iconController = controller,
            effects: [ShakeEffect(duration: 700.milliseconds, hz: 6)]),
      )),
      /*if (showGallery)
        if (showBooru)
          ListTile(
            style: ListTileStyle.drawer,
            title: const Text("Booru"),
            leading: const Icon(Icons.image),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
      if (showGallery)
        if (!showBooru)
          ListTile(
            style: ListTileStyle.drawer,
            title: const Text("Gallery"),
            leading: const Icon(Icons.photo_album),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const Directories();
              }));
            },
          ),*/
      ...destinations(),
      const NavigationDrawerDestination(
          icon: Icon(Icons.settings), label: Text("Settings"))
    ],
  );
}
