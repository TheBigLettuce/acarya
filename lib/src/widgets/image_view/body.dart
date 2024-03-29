// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../gesture_dead_zones.dart';

class ImageViewBody extends StatelessWidget {
  final void Function(int idx) onPageChanged;
  final PageController pageController;
  final void Function() onTap;
  final PhotoViewGalleryPageOptions Function(BuildContext, int) builder;
  final Widget? notes;
  final void Function() onLongPress;
  final int itemCount;
  final Widget Function(BuildContext, ImageChunkEvent?, int)? loadingBuilder;
  final bool isPaletteNull;

  final void Function()? onPressedRight;
  final void Function()? onPressedLeft;

  const ImageViewBody({
    super.key,
    required this.onPageChanged,
    required this.pageController,
    required this.builder,
    required this.notes,
    required this.loadingBuilder,
    required this.itemCount,
    required this.onLongPress,
    required this.onTap,
    required this.onPressedLeft,
    required this.onPressedRight,
    required this.isPaletteNull,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GestureDeadZones(
        left: true,
        right: true,
        onPressedRight: onPressedRight,
        onPressedLeft: onPressedLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onTap,
          child: PhotoViewGallery.builder(
            loadingBuilder: loadingBuilder,
            enableRotation: true,
            backgroundDecoration: BoxDecoration(
              color: isPaletteNull
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surfaceTint.withOpacity(0.2),
            ),
            onPageChanged: onPageChanged,
            pageController: pageController,
            itemCount: itemCount,
            builder: builder,
          ),
        ),
      ),
      if (notes != null) notes!
    ]);
  }
}
