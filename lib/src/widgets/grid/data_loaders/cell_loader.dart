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
import 'package:gallery/src/interfaces/booru_api/booru_api.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/interfaces/tags.dart';
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


// _GalleryImpl? _global;

// /// Callbacks related to the gallery.
// class _GalleryImpl implements GalleryApi {
//   final Isar db;
//   final bool temporary;
//   final List<_AndroidGallery> _temporaryApis = [];

//   bool isSavingTags = false;

//   _AndroidGallery? _currentApi;

//   void setup() {
  
//   }

//   @override
//   void updatePictures(List<DirectoryFile?> f, String bucketId, int startTime,
//       bool inRefresh, bool empty) {
//     // final st = _currentApi?.currentImages?.startTime;

//     // if (st == null || st > startTime) {
//     //   return;
//     // }

//     // if (_currentApi?.currentImages?.isBucketId(bucketId) != true) {
//     //   return;
//     // }

//     // final db = _currentApi?.currentImages?.db;
//     // if (db == null) {
//     //   return;
//     // }

//     // if (empty) {
//     //   _currentApi?.currentImages?.callback
//     //       ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, true);
//     //   return;
//     // }

//     // if (f.isEmpty) {
//     //   return;
//     // }

//     // try {
//     //   final out = f
//     //       .cast<DirectoryFile>()
//     //       .map((e) => SystemGalleryDirectoryFile(
//     //           id: e.id,
//     //           bucketId: e.bucketId,
//     //           notesFlat: Dbs.g.main.noteGallerys
//     //                   .getByIdSync(e.id)
//     //                   ?.text
//     //                   .join()
//     //                   .toLowerCase() ??
//     //               "",
//     //           name: e.name,
//     //           size: e.size,
//     //           isDuplicate:
//     //               RegExp(r'[(][0-9].*[)][.][a-zA-Z0-9].*').hasMatch(e.name),
//     //           isFavorite:
//     //               Dbs.g.blacklisted.favoriteMedias.getSync(e.id) != null,
//     //           lastModified: e.lastModified,
//     //           height: e.height,
//     //           width: e.width,
//     //           isGif: e.isGif,
//     //           isOriginal: PostTags.g.isOriginal(e.name),
//     //           originalUri: e.originalUri,
//     //           isVideo: e.isVideo,
//     //           tagsFlat: PostTags.g.getTagsPost(e.name).join(" ")))
//     //       .toList();

//     //   db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(out));
//     // } catch (e) {
//     //   log("updatePictures", level: Level.WARNING.value, error: e);
//     // }

//     // _currentApi?.currentImages?.callback
//     //     ?.call(db.systemGalleryDirectoryFiles.countSync(), inRefresh, false);
//   }

//   @override
//   void updateDirectories(List<Directory?> d, bool inRefresh, bool empty) {
//     // if (empty) {
//     //   _currentApi?.callback
//     //       ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, true);
//     //   for (final api in _temporaryApis) {
//     //     api.temporarySet?.call(db.systemGalleryDirectorys.countSync(), true);
//     //   }
//     //   return;
//     // }
//     // final blacklisted = Dbs.g.blacklisted.blacklistedDirectorys
//     //     .where()
//     //     .anyOf(d.cast<Directory>(),
//     //         (q, element) => q.bucketIdEqualTo(element.bucketId))
//     //     .findAllSync();
//     // final map = <String, void>{for (var i in blacklisted) i.bucketId: Null};
//     // d = List.from(d);
//     // d.removeWhere((element) => map.containsKey(element!.bucketId));

//     // final out = d
//     //     .cast<Directory>()
//     //     .map((e) => SystemGalleryDirectory(
//     //         bucketId: e.bucketId,
//     //         name: e.name,
//     //         volumeName: e.volumeName,
//     //         relativeLoc: e.relativeLoc,
//     //         thumbFileId: e.thumbFileId,
//     //         lastModified: e.lastModified))
//     //     .toList();

//     // db.writeTxnSync(() {
//     //   db.systemGalleryDirectorys.putAllSync(out);
//     // });

//     // _currentApi?.callback
//     //     ?.call(db.systemGalleryDirectorys.countSync(), inRefresh, false);
//     // for (final api in _temporaryApis) {
//     //   api.temporarySet?.call(db.systemGalleryDirectorys.countSync(), false);
//     // }
//   }

//   @override
//   void notify(String? target) {
//     // if (target == null || target == _currentApi?.currentImages?.target) {
//     //   _currentApi?.currentImages?.refreshGrid?.call();
//     // }
//     // _currentApi?.refreshGrid?.call();
//     // for (final api in _temporaryApis) {
//     //   api.refreshGrid?.call();
//     // }
//   }

//   // static GalleryImpl get g => _global!;

//   factory _GalleryImpl(bool temporary) {
//     if (_global != null) {
//       return _global!;
//     }

//     _global = _GalleryImpl._new(
//         DbsOpen.androidGalleryDirectories(temporary: temporary), temporary);
//     return _global!;
//   }

//   void _setCurrentApi(_AndroidGallery api) {
//     _currentApi = api;
//   }

//   void _unsetCurrentApi() {
//     _currentApi = null;
//   }

//   _GalleryImpl._new(this.db, this.temporary);
// }
