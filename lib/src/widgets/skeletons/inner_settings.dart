// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../gesture_dead_zones.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import 'skeleton_state.dart';

class InnerSettingsSkeleton extends StatelessWidget {
  final String pageDescription;
  final SkeletonState state;
  final List<Widget> children;
  final List<Widget>? appBarActions;

  const InnerSettingsSkeleton(
    this.pageDescription,
    this.state,
    this.children, {
    super.key,
    this.appBarActions,
  });

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        Navigator.pop(context);
      },
    };
    final insets = MediaQuery.viewPaddingOf(context);

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(
              context, describeKeys(bindings), pageDescription, () {
            state.mainFocus.requestFocus();
          })
        },
        child: Focus(
          autofocus: true,
          focusNode: state.mainFocus,
          child: Scaffold(
            drawerEnableOpenDragGesture:
                MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
            body: GestureDeadZones(
                child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  expandedHeight: 160,
                  flexibleSpace: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: FlexibleSpaceBar(
                        title: Text(
                          pageDescription,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )),
                      if (appBarActions != null)
                        ...appBarActions!.map((e) => SafeArea(
                                child: Padding(
                              padding: Platform.isAndroid
                                  ? const EdgeInsets.only(top: 4, bottom: 4)
                                  : const EdgeInsets.only(top: 8, bottom: 8),
                              child: e,
                            )))
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: insets.bottom),
                  sliver:
                      SliverList(delegate: SliverChildListDelegate(children)),
                )
              ],
            )),
          ),
        ));
  }
}
