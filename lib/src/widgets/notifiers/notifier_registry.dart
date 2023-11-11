// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/net/network_configuration.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/grid/grid_metadata.dart';
import 'package:gallery/src/widgets/grid/selection_glue.dart';
import 'package:gallery/src/widgets/notifiers/grid_metadata.dart';

import 'network_configuration.dart';
import 'notes_interface.dart';
// import 'package:gallery/src/net/network_configuration.dart';

class NotifierRegistry extends InheritedWidget {
  final List<InheritedWidget Function(Widget child)> notifiers;

  const NotifierRegistry(
      {super.key, required this.notifiers, required super.child});

  static List<InheritedWidget Function(Widget)> basicNotifiers<T extends Cell>(
      BuildContext context, GridMetadata<T> metadata) {
    return [
      (child) => NetworkConfigurationProvider(
            configuration: const NetworkConfiguration(),
            child: GridMetadataProvider<T>(
              metadata: metadata,
              child: child,
            ),
          )
    ];
  }

  static List<InheritedWidget Function(Widget)>
      genericNotifiers<T extends Cell>(
          BuildContext context,
          SelectionGlue<T>? glue,
          GridMetadata<T> metadata,
          NoteInterface<T> notes) {
    return [
      (child) => NetworkConfigurationProvider(
            configuration: const NetworkConfiguration(),
            child: GridMetadataProvider<T>(
                metadata: metadata,
                child: NoteInterfaceProvider<T>(
                  interface: notes,
                  child: glue != null
                      ? GlueHolder<T>(
                          glue: glue,
                          child: child,
                        )
                      : child,
                )),
          )
    ];
  }

  static void addNotifiersOn(
      BuildContext context, InheritedWidget Function(Widget child) f) {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      final widget =
          context.dependOnInheritedWidgetOfExactType<NotifierRegistry>();

      widget?.notifiers.add(f);
    });
  }

  static List<InheritedWidget Function(Widget child)>? inherit(
      BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<NotifierRegistry>();

    return widget?.notifiers;
  }

  static Widget Function(Widget child)? registrerOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<NotifierRegistry>();

    for (final f in widget!.notifiers) {
      print(f);
    }

    return widget == null
        ? null
        : (child) {
            if (widget.notifiers.isEmpty) {
              return child;
            }

            return recursion(
                widget.notifiers, widget.notifiers.length - 1, child);
          };
  }

  static Widget recursion(
      List<InheritedWidget Function(Widget child)> l, int idx, Widget child) {
    if (idx < 0) {
      return child;
    }

    final f = l[idx];

    return f(recursion(l, idx - 1, child));
  }

  @override
  bool updateShouldNotify(NotifierRegistry oldWidget) =>
      oldWidget.notifiers != notifiers;
}
