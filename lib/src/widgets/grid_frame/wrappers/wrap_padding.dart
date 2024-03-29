// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class _WrapPadding<T extends Cell> extends StatelessWidget {
  final PreferredSizeWidget? footer;
  final SelectionGlue<T> selectionGlue;
  final double systemNavigationInsets;
  final bool sliver;
  final bool addFabPadding;

  final Widget? child;

  const _WrapPadding({
    super.key,
    required this.footer,
    required this.selectionGlue,
    required this.systemNavigationInsets,
    this.sliver = true,
    this.addFabPadding = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final insets = EdgeInsets.only(
        bottom: (addFabPadding ? kFloatingActionButtonMargin * 2 + 24 + 8 : 0) +
            (selectionGlue.keyboardVisible()
                ? 0
                : systemNavigationInsets +
                    (selectionGlue.isOpen() //&&
                        ? selectionGlue.barHeight()
                        : selectionGlue.persistentBarHeight
                            ? selectionGlue.barHeight()
                            : 0)) +
            (footer != null ? footer!.preferredSize.height : 0));

    return sliver
        ? SliverPadding(
            padding: insets,
            sliver: child,
          )
        : Padding(
            padding: insets,
            child: child,
          );
  }
}
