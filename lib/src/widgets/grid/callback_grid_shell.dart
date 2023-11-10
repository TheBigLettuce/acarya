// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/notifiers/grid_footer.dart';

import 'app_bar/grid_app_bar_title.dart';
import 'app_bar/wrap_badge_cell_count_title_widget.dart';
import 'callback_grid_base.dart';
import 'data_loaders/interface.dart';
import 'grid_app_bar.dart';
import 'notifiers/grid_mutation_interface_holder.dart';
import 'notifiers/grid_selection_holder.dart';
import 'search_and_focus.dart';

class CallbackGridShell<T extends Cell> extends StatelessWidget {
  /// The cell includes some keybinds by default.
  /// If [additionalKeybinds] is not null, they are added together.
  final Map<SingleActivator, void Function()> keybinds;

  /// The main focus node of the grid.
  final FocusNode mainFocus;

  /// If [footer] is not null, displayed at the bottom of the screen,
  /// on top of the [child].
  final PreferredSizeWidget? footer;

  final InheritedWidget Function(Widget child)? registerNotifiers;

  final Widget? fab;

  final List<Widget> appBarActions;

  final SearchAndFocus? search;

  final BackgroundDataLoader<T, int> loader;

  /// The actual grid widget.
  final Widget child;

  const CallbackGridShell({
    super.key,
    required this.keybinds,
    required this.mainFocus,
    required this.appBarActions,
    required this.loader,
    this.search,
    this.footer,
    this.registerNotifiers,
    this.fab,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Notifiers(
        footerSize: footer?.preferredSize.height,
        registerNotifiers: registerNotifiers,
        child: CallbackShortcuts(
          bindings: keybinds,
          child: Focus(
              autofocus: true,
              focusNode: mainFocus,
              child: DataLoaderHolder<T>(
                loader: loader,
                child: GridSelectionHolder<T>(
                    child: CallbackGridBase<T>(
                  onRefresh: () {
                    return Future.value();
                  },
                  appBar: GridAppBar(
                      actions: appBarActions,
                      bottomWidget: null,
                      centerTitle: true,
                      leading: Text(""),
                      // search: widget.metadata.search,
                      title: GridAppBarTitle(
                          onPressed: () {},
                          searchWidget: search,
                          child: const WrapBadgeCellCountTitleWidget(
                            child: SearchCharacterTitle(),
                          ))),
                  child: fab == null && footer == null
                      ? child
                      : Stack(
                          children: [
                            child,
                            if (footer != null)
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.systemGestureInsetsOf(
                                            context)
                                        .bottom,
                                  ),
                                  child: footer!,
                                ),
                              ),
                            if (fab != null)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: fab,
                              ),
                          ],
                        ),
                )),
              )),
        ));
  }
}

class _Notifiers extends StatelessWidget {
  final double? footerSize;
  final InheritedWidget Function(Widget child)? registerNotifiers;
  final Widget child;

  const _Notifiers(
      {super.key,
      required this.registerNotifiers,
      required this.footerSize,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return GridFooterNotifier(
        size: footerSize,
        child: registerNotifiers == null ? child : registerNotifiers!(child));
  }
}
