// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:gallery/src/widgets/notifiers/grid_element_count.dart';

class DataLoaderHolder<T extends Cell> extends StatefulWidget {
  final BackgroundDataLoader<T, int> loader;

  final Widget child;

  const DataLoaderHolder(
      {super.key, required this.loader, required this.child});

  @override
  State<DataLoaderHolder<T>> createState() => _DataLoaderHolderState<T>();
}

class _DataLoaderHolderState<T extends Cell>
    extends State<DataLoaderHolder<T>> {
  int _count = 0;

  @override
  void initState() {
    super.initState();

    widget.loader.listenStatus((i) {
      _tick(i);
    });
  }

  @override
  void dispose() {
    widget.loader.dispose();

    super.dispose();
  }

  void _tick(int newCount) {
    setState(() {
      _count = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridElementCountNotifier(
      count: _count,
      child: widget.child,
    );
  }
}
