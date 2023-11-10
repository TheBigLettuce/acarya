// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/interfaces/tags.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import 'interface.dart';

part 'cell_controller.dart';
part 'booru_api_controller.dart';

final Map<int, BackgroundCellLoader> _cache = {};

class BackgroundCellLoader<T extends Cell, I>
    implements BackgroundDataLoader<T, int> {
  final Isar _instance;
  final List<IsarGeneratedSchema> _schemas;
  final T? Function(Isar, int) _getCell;
  final bool disposable;
  final LoaderStateController Function(BackgroundCellLoader<T, I>) _makeState;

  bool _initCalled = false;
  late final ReceivePort _rx;
  late final Stream _isolateEvents;
  late final SendPort _send;
  late final Isolate _isolate;

  late final LoaderStateController _stateController;

  T Function(T)? _transform;
  StreamSubscription<void>? _status;

  BackgroundCellLoader(this._getCell, this._instance, this._schemas,
      {required LoaderStateController Function(BackgroundCellLoader<T, I>)
          makeState,
      this.disposable = true})
      : _makeState = makeState;

  static void disposeCached(int key) {
    _cache.remove(key)?.dispose();
  }

  factory BackgroundCellLoader.cached(int key) =>
      _cache[key]! as BackgroundCellLoader<T, I>;

  factory BackgroundCellLoader.cache(
    int key,
    (
      T? Function(Isar, int),
      Isar instance,
      List<IsarGeneratedSchema> schemas,
      LoaderStateController Function(BackgroundCellLoader<T, I>) makeState
    )
            Function()
        init,
  ) {
    final l = _cache[key];
    if (l != null) {
      return l as BackgroundCellLoader<T, I>;
    }

    final (getCell, instance, schemas, makeState) = init();
    final loader = BackgroundCellLoader<T, I>(getCell, instance, schemas,
        disposable: false, makeState: makeState);
    _cache[key] = loader;

    return loader;
  }

  @override
  LoaderStateController get state => _stateController;

  @override
  Isolate get isolate => _isolate;

  @override
  T? getSingle(int token) {
    assert(_status != null);
    if (_status == null) {
      return null;
    }

    final cell = _getCell(_instance, token);

    return cell == null
        ? cell
        : _transform != null
            ? _transform!(cell)
            : cell;
  }

  static void _startIsolate<T extends Cell, I>(
      (
        SendPort port,
        List<IsarGeneratedSchema> schemas,
        String dir,
        String name
      ) record) async {
    final (port, schemas, dir, name) = record;

    final rx = ReceivePort();
    final db = Isar.open(
        schemas: schemas, directory: dir, name: name, inspector: false);
    port.send(rx.sendPort);

    await for (final ControlMessage e in rx) {
      switch (e) {
        case Data<T>():
          db.write((i) => db.collection<I, T>().putAll(e.l));
          if (e.end) {
            port.send(LoaderState.idle);
          } else {
            port.send(LoaderState.loading);
          }
          break;
        case Reset():
          db.write((i) => i.collection<I, T>().clear());
          if (!e.silent) {
            port.send(LoaderState.idle);
          }
        default:
      }
    }
  }

  @override
  Future<void> init() async {
    if (_initCalled == true) {
      return;
    }
    _initCalled = true;

    _rx = ReceivePort("Loader(Port): ${_instance.directory}/${_instance.name}");
    _isolate = await Isolate.spawn(
      _startIsolate<T, I>,
      (_rx.sendPort, _schemas, _instance.directory, _instance.name),
      debugName: "Loader: ${_instance.directory}/${_instance.name}",
    );

    _isolateEvents = _rx.asBroadcastStream();

    _send = await _isolateEvents.first;

    _stateController = _makeState(this);

    return;
  }

  @override
  void listenStatus(void Function(int p1) f) {
    if (_status != null) {
      _status!.cancel();
    }

    _status = _instance
        .collection<I, T>()
        .watchLazy(fireImmediately: true)
        .listen((_) {
      f(_instance.collection<I, T>().count());
    });
  }

  @override
  void transformData(T Function(T p1)? f) {
    assert(_status == null);
    if (_status != null) {
      return;
    }
    _transform = f;
  }

  @override
  void dispose() {
    if (!disposable) {
      return;
    }
    // assert(_status != null);

    _status?.cancel();
    _isolate.kill();
    _rx.close();
    _stateController.dispose();
  }

  @override
  void send(ControlMessage m) {
    _send.send(m);
  }
}
