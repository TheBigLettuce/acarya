// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/interfaces/tags.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/interfaces/filtering/sorting_mode.dart';
import 'package:gallery/src/widgets/grid/data_loaders/interface.dart';

part 'cell_controller.dart';
part 'booru_api_controller.dart';
part 'cell_transformer.dart';
part 'binary_controller.dart';

final Map<int, BackgroundCellLoader> _cache = {};

class BackgroundCellLoader<T extends Cell, I>
    implements BackgroundDataLoader<T, int> {
  BackgroundCellLoader(
    this._getCell,
    this._instance,
    this._schemas, {
    required LoaderStateController Function(BackgroundCellLoader<T, I>)
        makeState,
    required CellDataTransformer<T, I> Function(BackgroundCellLoader<T, I>)?
        makeTransformer,
    required this.handler,
    this.disposable = true,
  })  : _makeState = makeState,
        _makeTransformer = makeTransformer {
    transformer = _makeTransformer?.call(this);
  }

  final Isar _instance;
  final List<IsarGeneratedSchema> _schemas;
  final T? Function(Isar, int) _getCell;
  final bool disposable;
  final LoaderStateController Function(BackgroundCellLoader<T, I>) _makeState;
  final CellDataTransformer<T, I> Function(BackgroundCellLoader<T, I>)?
      _makeTransformer;

  final void Function(HandlerPayload record) handler;

  @override
  late final CellDataTransformer<T, I>? transformer;

  late final ReceivePort _rx;
  late final Stream _isolateEvents;
  late final SendPort _send;
  late final Isolate _isolate;

  late final LoaderStateController _stateController;

  StreamSubscription<void>? _status;
  bool _initCalled = false;

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
        : transformer != null
            ? transformer!.transformCell(cell)
            : cell;
  }

  @override
  Future<void> init() async {
    if (_initCalled == true) {
      return;
    }
    _initCalled = true;

    _rx = ReceivePort("Loader(Port): ${_instance.directory}/${_instance.name}");
    _isolate = await Isolate.spawn(
      handler,
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
      if (transformer == null) {
        f(_instance.collection<I, T>().count());
      } else {
        transformer!.transformStatusCallback(f);
      }
    });
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

  static int directoryBinaryType = 0;
  static int filesBinaryType = 1;

  static int filesResetContextState = 0;

  static void disposeCached(int key) {
    _cache.remove(key)?.dispose();
  }

  factory BackgroundCellLoader.cached(int idx) =>
      _cache[idx] as BackgroundCellLoader<T, I>;

  static DirectoriesLoader directories() =>
      _cache[kAndroidGalleryLoaderKey] as DirectoriesLoader;

  static FilesLoader filesPrimary() =>
      _cache[kAndroidFilesPrimaryLoaderKey] as FilesLoader;
  static FilesLoader filesSecondary() =>
      _cache[kAndroidFilesSecondaryLoaderKey] as FilesLoader;

  static Future<void> cacheDirectories() async {
    _cache[kAndroidGalleryLoaderKey] = DirectoriesLoader(
        (db, idx) => null, DbsOpen.androidGalleryFiles(), kFilesSchemas,
        makeState: (instance) => CellLoaderStateController(instance),
        handler: CellLoaderHandlers.directories,
        makeTransformer: (instance) => CellDataTransformer(
            instance,
            (_, cell) => cell,
            (_) => 0,
            FilteringMode.noFilter,
            SortingMode.none));

    await _cache[kAndroidGalleryLoaderKey]!.init();

    return;
  }

  static Future<void> cacheFiles() async {
    FilesLoader make() => FilesLoader(
        (db, idx) => null, DbsOpen.androidGalleryFiles(), kFilesSchemas,
        handler: CellLoaderHandlers.files,
        makeState: (instance) => CellLoaderStateController(instance),
        makeTransformer: (instance) => CellDataTransformer(
            instance,
            (_, cell) => cell,
            (_) => 0,
            FilteringMode.noFilter,
            SortingMode.none));

    _cache[kAndroidFilesPrimaryLoaderKey] = make();
    _cache[kAndroidFilesSecondaryLoaderKey] = make();

    await _cache[kAndroidFilesPrimaryLoaderKey]!.init();
    await _cache[kAndroidFilesSecondaryLoaderKey]!.init();

    return;
  }

  factory BackgroundCellLoader.cache(
      int key,
      (
        T? Function(Isar, int),
        Isar instance,
        List<IsarGeneratedSchema> schemas,
        LoaderStateController Function(BackgroundCellLoader<T, I>) makeState,
        CellDataTransformer<T, I> Function(
            BackgroundCellLoader<T, I>)? makeTransformer
      )
              Function()
          init,
      {HandlerFn? handler}) {
    final l = _cache[key];
    if (l != null) {
      return l as BackgroundCellLoader<T, I>;
    }

    final (getCell, instance, schemas, makeState, makeTransformer) = init();
    final loader = BackgroundCellLoader<T, I>(getCell, instance, schemas,
        disposable: false,
        makeState: makeState,
        handler: handler ?? CellLoaderHandlers.basic<T, I>,
        makeTransformer: makeTransformer);
    _cache[key] = loader;

    return loader;
  }
}

typedef DirectoriesLoader = BackgroundCellLoader<SystemGalleryDirectory, int>;
typedef FilesLoader = BackgroundCellLoader<SystemGalleryDirectoryFile, int>;

typedef HandlerFn = void Function(HandlerPayload);

typedef HandlerPayload = (
  SendPort port,
  List<IsarGeneratedSchema> schemas,
  String dir,
  String name
);

abstract class CellLoaderHandlers {
  static void directories<SystemGalleryDirectory, int>(
      HandlerPayload record) async {
    final (port, db, rx) = _normalSequence(record);
  }

  static void files<SystemGalleryDirectoryFile, int>(
      HandlerPayload record) async {
    final (port, db, rx) = _normalSequence(record);
  }

  static void basic<T extends Cell, I>(HandlerPayload record) async {
    final (port, db, rx) = _normalSequence(record);

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
        case Poll():
          port.send(e);
        default:
      }
    }
  }

  static (SendPort, Isar, ReceivePort) _normalSequence(HandlerPayload payload) {
    final (port, schemas, dir, name) = payload;

    final rx = ReceivePort();
    final db = Isar.open(
        schemas: schemas, directory: dir, name: name, inspector: false);
    port.send(rx.sendPort);

    return (port, db, rx);
  }
}
