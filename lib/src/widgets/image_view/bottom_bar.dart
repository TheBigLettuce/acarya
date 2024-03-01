// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../notifiers/app_bar_visibility.dart';

class ImageViewBottomAppBar extends StatelessWidget {
  final TextEditingController textController;
  final List<Widget> children;

  const ImageViewBottomAppBar({
    super.key,
    required this.textController,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
        effects: const [
          FadeEffect(begin: 1, end: 0, duration: Duration(milliseconds: 500))
        ],
        autoPlay: false,
        target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
        child: IgnorePointer(
          ignoring: !AppBarVisibilityNotifier.of(context),
          child: BottomAppBar(
            child: Wrap(
              spacing: 4,
              children: children,
            ),
          ),
        ));
  }
}
