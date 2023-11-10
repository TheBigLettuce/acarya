// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../notifiers/notifier_registry.dart';

class NotifierRegistryHolder extends StatelessWidget {
  final List<InheritedWidget Function(Widget)> l;
  final Widget child;

  const NotifierRegistryHolder(
      {super.key, required this.l, required this.child});

  static Widget inherit(BuildContext context,
      List<InheritedWidget Function(Widget)> l, Widget child) {
    final l1 = NotifierRegistry.inherit(context);
    final l2 = l1 == null ? l : [...l1, ...l];
    print(l2);

    return NotifierRegistry(
      notifiers: l2,
      child: l.isEmpty
          ? child
          : NotifierRegistry.recursion(
              l,
              l.length - 1,
              child,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotifierRegistry(
      notifiers: l,
      child: l.isEmpty
          ? child
          : NotifierRegistry.recursion(l, l.length - 1, child),
    );
  }
}
