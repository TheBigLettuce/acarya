// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/widgets/grid/data_loaders/dummy_controller.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';
import 'package:isar/isar.dart';

class ReadOnlyDataLoader<T, J, ID> implements BackgroundDataLoader<T, J> {
  final Isar _instance;
  final T? Function(Isar, J) _getCell;

  StreamSubscription<void>? _subscription;

  ReadOnlyDataLoader(this._instance, this._getCell);

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  T? getSingle(J token) => _getCell(_instance, token);

  @override
  Future<void> init() => Future.value();

  @override
  Isolate get isolate => throw UnimplementedError();

  @override
  void listenStatus(void Function(int p1) f) {
    _subscription?.cancel();

    _instance
        .collection<ID, T>()
        .watchLazy(fireImmediately: true)
        .listen((event) {
      f(_instance.collection<ID, T>().count());
    });
  }

  @override
  void send(ControlMessage m) {
    assert(true, ".send on ReadOnlyDataLoader should not be used");
  }

  @override
  LoaderStateController get state => const DummyLoaderStateController();

  @override
  void transformData(T Function(T p1)? f) {
    // TODO: implement transformData
  }
}
