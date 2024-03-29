// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/pages/more/settings/network_status.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';

import 'skeleton_state.dart';

class HomeSkeleton extends StatelessWidget {
  final String pageDescription;
  final SkeletonState state;
  final Widget Function(BuildContext) f;
  final int selectedRoute;
  final Widget? navBar;

  const HomeSkeleton(
    this.pageDescription,
    this.state,
    this.f, {
    super.key,
    required this.selectedRoute,
    required this.navBar,
  });

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {};

    return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription,
            () {
          state.mainFocus.requestFocus();
        })
      },
      child: Focus(
        autofocus: true,
        focusNode: state.mainFocus,
        child: Scaffold(
          extendBody: selectedRoute == 4 ? false : true,
          appBar: null,
          drawerEnableOpenDragGesture:
              MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
          key: state.scaffoldKey,
          bottomNavigationBar: navBar,
          body: GestureDeadZones(
              child: Stack(
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Easing.standard,
                padding:
                    EdgeInsets.only(top: NetworkStatus.g.hasInternet ? 0 : 24),
                child: Builder(builder: f),
              ),
              if (!NetworkStatus.g.hasInternet)
                Animate(
                  autoPlay: true,
                  effects: [
                    MoveEffect(
                        duration: 200.ms,
                        curve: Easing.standard,
                        begin: Offset(
                            0, -(24 + MediaQuery.viewPaddingOf(context).top)),
                        end: const Offset(0, 0))
                  ],
                  child: AnimatedContainer(
                    duration: 200.ms,
                    curve: Easing.standard,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.8),
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.viewPaddingOf(context).top),
                      child: SizedBox(
                        height: 24,
                        width: MediaQuery.sizeOf(context).width,
                        child: Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.signal_wifi_off_outlined,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.8),
                              ),
                              const Padding(padding: EdgeInsets.only(right: 4)),
                              Text(
                                AppLocalizations.of(context)!.noInternet,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.8),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )),
        ),
      ),
    );
  }
}
