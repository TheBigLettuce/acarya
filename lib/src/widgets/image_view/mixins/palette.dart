// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:flutter/material.dart";
import "package:palette_generator/palette_generator.dart";

mixin ImageViewPaletteMixin on State<ImageView> {
  PaletteGenerator? currentPalette;
  PaletteGenerator? previousPallete;

  void extractPalette(
    Contentable currentCell,
    GlobalKey<ScaffoldState> scaffoldKey,
    ScrollController scrollController,
    int currentPage,
    void Function() resetAnimation,
  ) {
    final t = currentCell.widgets.tryAsThumbnailable();
    if (t == null) {
      return;
    }

    PaletteGenerator.fromImageProvider(
      t,
    ).then((value) {
      previousPallete = currentPalette;
      currentPalette = value;

      resetAnimation();

      setState(() {});
    }).onError((e, trace) {
      ImageView.log.warning("extractPalette", e, trace);
    });
  }
}
