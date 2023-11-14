// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/interfaces/booru_api/booru.dart';
import 'package:gallery/src/interfaces/booru_api/booru_api_state.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/interfaces/tags.dart';
import 'package:gallery/src/plugs/platform_channel.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/interfaces/filtering/sorting_mode.dart';
import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';

import '../../../interfaces/background_data_loader/control_message.dart';
import '../../../interfaces/background_data_loader/data_transformer.dart';
import '../../../interfaces/background_data_loader/loader_keys.dart';
import '../../../interfaces/background_data_loader/loader_state_controller.dart';

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
    String? debugName,
  })  : _makeState = makeState,
        _debugName = debugName,
        _makeTransformer = makeTransformer {
    transformer = _makeTransformer?.call(this);
  }

  final String? _debugName;
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

    _rx = ReceivePort(
        "Loader(Port): ${_debugName ?? _instance.directory}/${_instance.name}");
    _isolate = await Isolate.spawn(
      handler,
      (_rx.sendPort, _schemas, _instance.directory, _instance.name),
      debugName:
          "Loader: ${_debugName ?? _instance.directory}/${_instance.name}",
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

  static const int directoryBinaryType = 0;
  static const int filesBinaryType = 1;

  static const int filesResetContextState = 0;
  static const int booruInitContextState = 1;
  static const int booruResetPostsContextState = 2;
  static const int booruNextPostsContextState = 3;

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
    if (_cache[kAndroidGalleryLoaderKey] != null) {
      return;
    }

    final db = DbsOpen.androidGalleryDirectories(temporary: true);
    _cache[kAndroidGalleryLoaderKey] = DirectoriesLoader(
        (db, idx) => db.systemGalleryDirectorys.get(idx + 1),
        db,
        kDirectoriesSchemas,
        makeState: (instance) =>
            CellLoaderStateController(instance, onReset: (_) {
              instance.send(const Reset());
              PlatformFunctions.refreshGallery();
            }),
        handler: CellLoaderHandlers.directories,
        makeTransformer: (instance) => CellDataTransformer(
              instance,
              (_, cell) => cell,
              (instance) => db.systemGalleryDirectorys.count(),
              FilteringMode.noFilter,
              SortingMode.none,
            ),
        debugName: "Android Directories",
        disposable: false);

    await _cache[kAndroidGalleryLoaderKey]!.init();

    return;
  }

  static Future<void> cacheFiles() async {
    if (_cache[kAndroidFilesSecondaryLoaderKey] != null ||
        _cache[kAndroidFilesPrimaryLoaderKey] != null) {
      return;
    }

    final db = DbsOpen.androidGalleryFiles();

    FilesLoader make(String debugName) =>
        FilesLoader((db, idx) => null, db, kFilesSchemas,
            handler: CellLoaderHandlers.files,
            makeState: (instance) => CellLoaderStateController(instance),
            makeTransformer: (instance) => CellDataTransformer(
                  instance,
                  (_, cell) => cell,
                  (_) => db.systemGalleryDirectoryFiles.count(),
                  FilteringMode.noFilter,
                  SortingMode.none,
                ),
            debugName: debugName,
            disposable: false);

    _cache[kAndroidFilesPrimaryLoaderKey] = make("Android Files Primary");
    _cache[kAndroidFilesSecondaryLoaderKey] = make("Android Files Secondary");

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
  static void directories(HandlerPayload record) async {
    final (port, db, rx) = _normalSequence(record);

    final incrementer = _Incrementer(db.systemGalleryDirectorys.count());
    final codec = _GalleryApiCodec(incrementer);

    await for (final ControlMessage e in rx) {
      switch (e) {
        case Reset():
          db.write((i) => i.systemGalleryDirectorys.clear());
          incrementer.reset();
          if (!e.silent) {
            port.send(LoaderState.idle);
          }
        case Binary():
          if (e.type != BackgroundCellLoader.directoryBinaryType) {
            throw "directories handler supports binary messages only of type BackgroundCellLoader.directoryBinaryType";
          }

          final decoded = codec.decodeMessage(e.data);

          final directories = decoded[0] as List<Object?>;
          final inRefresh = decoded[1] as bool;
          final empty = decoded[2] as bool;

          if (empty) {
            incrementer.currentValue = db.systemGalleryDirectorys.count();

            port.send(LoaderState.idle);
            continue;
          }

          db.write((i) => i.systemGalleryDirectorys.putAll(directories.cast()));
          incrementer.currentValue = db.systemGalleryDirectorys.count();

          if (inRefresh) {
            port.send(LoaderState.loading);
          } else {
            port.send(LoaderState.idle);
          }
        case Poll():
          port.send(e);
        default:
          assert(
              false, "Received unsupported message of type ${e.runtimeType}");
      }
    }

    assert(false, "directories handler exited");
  }

  static void files(HandlerPayload record) async {
    final (port, db, rx) = _normalSequence(record);

    final incrementer = _Incrementer(db.systemGalleryDirectoryFiles.count());
    final codec = _GalleryApiCodec(incrementer);
    String currentContext = "";

    await for (final ControlMessage e in rx) {
      switch (e) {
        case Reset():
          db.write((i) => i.systemGalleryDirectoryFiles.clear());
          incrementer.reset();
          if (!e.silent) {
            port.send(LoaderState.idle);
          }
        case ChangeContext():
          if (e.contextStage != BackgroundCellLoader.filesResetContextState) {
            assert(false,
                "files handler supports only BackgroundCellLoader.filesResetContextState context stage");
            continue;
          }

          currentContext = e.data;
          db.write((i) => i.systemGalleryDirectoryFiles.clear());
          incrementer.reset();
          port.send(LoaderState.idle);
        case Binary():
          if (e.type != BackgroundCellLoader.filesBinaryType) {
            throw "files handler supports binary messages only of type BackgroundCellLoader.filesBinaryType";
          }
          final decoded = codec.decodeMessage(e.data) as List<Object?>;

          final files = decoded[0] as List<SystemGalleryDirectoryFile>;
          final bucketId = decoded[1] as String;
          final _ = decoded[2] as int;
          final inRefresh = decoded[3] as bool;
          final empty = decoded[4] as bool;

          if (currentContext != bucketId) {
            incrementer.currentValue = db.systemGalleryDirectoryFiles.count();

            continue;
          }

          if (empty) {
            incrementer.currentValue = db.systemGalleryDirectoryFiles.count();

            port.send(LoaderState.idle);
            continue;
          }

          db.write((i) => i.systemGalleryDirectoryFiles.putAll(files));
          incrementer.currentValue = db.systemGalleryDirectoryFiles.count();

          if (inRefresh) {
            port.send(LoaderState.loading);
          } else {
            port.send(LoaderState.idle);
          }
        case Poll():
          port.send(e);
        default:
          assert(
              false, "Received unsupported message of type ${e.runtimeType}");
      }
    }
  }

  // static void booruApi(HandlerPayload record) async {
  //   final (port, db, rx) = _normalSequence(record);

  //   final incrementer = _Incrementer(db.posts.count());
  //   late final BooruAPIState currentApi;
  //   late final BooruTagging excludedTags;

  //   void reset() {
  //     db.write((i) => i.posts.clear());
  //     incrementer.reset();
  //   }

  //   int? lastId;

  //   await for (final ControlMessage e in rx) {
  //     switch (e) {
  //       case ChangeContext():
  //         switch (e.contextStage) {
  //           case BackgroundCellLoader.booruInitContextState:
  //             final (booru, page) = (e.data as (Booru, int?));
  //             currentApi = BooruAPIState.fromEnum(booru, page: page);
  //             excludedTags = TagManager.fromEnum(booru, true).excluded;
  //             port.send(LoaderState.idle);
  //           case BackgroundCellLoader.booruResetPostsContextState:
  //             reset();

  //             final (posts, lid) = await currentApi.page(0, "", excludedTags);
  //             db.write((i) => i.posts.putAll(posts));
  //             lastId = lid;
  //             port.send(LoaderState.idle);
  //           case BackgroundCellLoader.booruNextPostsContextState:
  //           final (posts, lid) = await currentApi.fromPost(postId, tags, excludedTags);
  //           default:
  //             assert(false, "Unknown context stage ${e.contextStage}");
  //             continue;
  //         }

  //       case Reset():
  //         reset();

  //         if (!e.silent) {
  //           port.send(LoaderState.idle);
  //         }
  //       case Poll():
  //         port.send(e);
  //       default:
  //         assert(
  //             false, "Received unsupported message of type ${e.runtimeType}");
  //     }
  //   }
  // }

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
        case Reset():
          db.write((i) => i.collection<I, T>().clear());
          if (!e.silent) {
            port.send(LoaderState.idle);
          }
        case Poll():
          port.send(e);
        default:
          assert(
              false, "Received unsupported message of type ${e.runtimeType}");
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

class _Incrementer {
  _Incrementer(this.currentValue);
  int currentValue = 0;

  // void increment() => currentValue += 1;
  int next() {
    currentValue += 1;

    return currentValue;
  }

  void reset() => currentValue = 0;
}

class _GalleryApiCodec extends StandardMessageCodec {
  final _Incrementer _incrementer;

  const _GalleryApiCodec(this._incrementer);
  // @override
  // void writeValue(WriteBuffer buffer, Object? value) {
  //   if (value is SystemGalleryDirectory) {
  //     buffer.putUint8(128);
  //     writeValue(buffer, value.encode());
  //   } else if (value is DirectoryFile) {
  //     buffer.putUint8(129);
  //     writeValue(buffer, value.encode());
  //   } else {
  //     super.writeValue(buffer, value);
  //   }
  // }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        final i = _incrementer.next();
        print("_c,$i");
        return SystemGalleryDirectory.decode(readValue(buffer)!, i);
      case 129:
        return SystemGalleryDirectoryFile.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
