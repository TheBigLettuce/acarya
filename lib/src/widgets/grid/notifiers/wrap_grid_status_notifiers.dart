// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:gallery/src/widgets/notifiers/is_refreshing.dart';
import 'package:gallery/src/widgets/notifiers/is_selecting.dart';

class WrapGridStatusNotifiers extends StatefulWidget {
  final LoaderStateController stateController;
  final Widget child;

  const WrapGridStatusNotifiers(
      {super.key, required this.stateController, required this.child});

  @override
  State<WrapGridStatusNotifiers> createState() =>
      _WrapGridStatusNotifiersState();
}

class _WrapGridStatusNotifiersState extends State<WrapGridStatusNotifiers> {
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();

    widget.stateController.listen(() {
      setState(() {});
    });

    widget.stateController.reset();
  }

  @override
  void dispose() {
    widget.stateController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IsRefreshingNotifier(
        isRefreshing: widget.stateController.currentState != LoaderState.idle,
        child: IsSelectingNotifier(
          isSelecting: _isSelecting,
          child: widget.child,
        ));
  }
}
