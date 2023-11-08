// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../notifiers/is_selecting.dart';
import '../search_and_focus.dart';

class SearchCharacterTitle extends StatelessWidget {
  final String? text;

  const SearchCharacterTitle({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? "探",
      style: text != null
          ? null
          : TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontFamily: "ZenKurenaido",
            ),
    );
  }
}

class GridAppBarTitle extends StatelessWidget {
  final void Function() onPressed;
  final SearchAndFocus? searchWidget;
  final Widget child;

  const GridAppBarTitle(
      {super.key,
      required this.onPressed,
      required this.searchWidget,
      required this.child});

  @override
  Widget build(BuildContext context) {
    if (searchWidget == null) {
      return child;
    }

    return Animate(
      effects: [
        const FadeEffect(begin: 1, end: 0),
        SwapEffect(builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: searchWidget!.search,
          );
        })
      ],
      target: IsSelectingNotifier.of(context) ? 1 : 0,
      child: GestureDetector(
        onTap: onPressed,
        child: AbsorbPointer(
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
