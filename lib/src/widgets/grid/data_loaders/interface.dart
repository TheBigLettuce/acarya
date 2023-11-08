import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/interfaces/cell.dart';
import 'package:isar/isar.dart';

const kAndroidGalleryLoaderKey = 0;
const kMainGridLoaderKey = 1;

/// Load data in a background isolate.
/// Depends on the ability of writing to the source on a different Isolate.
sealed class BackgroundDataLoader<T, J> {
  /// Isolate associated with the loader.
  /// [listenStatus] should be called before accessing [isolate].
  Isolate get isolate;

  /// Begin listening for the events in the source.
  /// After the call to [listenStatus] complete, [isolate], [send]
  /// and [dispose] become available.
  /// Trying to access [listenStatus], [send] or [dispose] before [listenStatus]'s future
  /// complete is undefined behaviour.
  Future<void> listenStatus(void Function(int) f);

  /// Apply transformations to the data before it is emitted by [getSingle].
  void transformData(T Function(T)? f);

  /// Return the single piece of data.
  /// This is used in the widget builders.
  T? getSingle(J token);

  /// Send the data for the insertion.
  /// [l] should be immutable, otherwise there is not much
  /// benefit in using [BackgroundDataLoader].
  /// [listenStatus] should be called before calling [send].
  void send(List<T> l);

  /// Shutdown the loader. After the call to [dispose],
  /// the instance is invalid and should not be used.
  /// [listenStatus] should be called before calling [dispose].
  void dispose();

  const BackgroundDataLoader();
}

class DummyBackgroundLoader<T, J> implements BackgroundDataLoader<T, J> {
  @override
  void dispose() {}

  @override
  T? getSingle(J token) => null;

  @override
  Isolate get isolate => throw UnimplementedError();

  @override
  Future<void> listenStatus(void Function(int p1) f) {
    return Future.value();
  }

  @override
  void send(List<T> l) {}

  @override
  void transformData(T Function(T p1)? f) {}
}

final Map<int, BackgroundCellLoader> _cache = {};

class BackgroundCellLoader<T extends Cell, J>
    implements BackgroundDataLoader<T, J> {
  final Isar _instance;
  final List<IsarGeneratedSchema> _schemas;
  final T? Function(Isar, J) _getCell;
  final bool disposable;

  late final ReceivePort _rx;
  late final Stream _isolateEvents;
  late final SendPort _send;
  late final Isolate _isolate;

  T Function(T)? _transform;
  StreamSubscription<void>? _status;

  bool _disposeBeforeListen = false;

  BackgroundCellLoader(this._getCell, this._instance, this._schemas,
      {this.disposable = true});

  static void disposeCached(int key) {
    _cache[key]?.dispose();
  }

  factory BackgroundCellLoader.cached(
    int key,
    (T? Function(Isar, J), Isar instance, List<IsarGeneratedSchema> schemas)
            Function()
        init,
  ) {
    final l = _cache[key];
    if (l != null) {
      return l as BackgroundCellLoader<T, J>;
    }

    final (getCell, instance, schemas) = init();
    final loader = BackgroundCellLoader<T, J>(getCell, instance, schemas,
        disposable: false);
    _cache[key] = loader;

    return loader;
  }

  @override
  Isolate get isolate => _isolate;

  @override
  T? getSingle(J token) {
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

  static void _startIsolate<T extends Cell, J>(
      (
        SendPort port,
        List<IsarGeneratedSchema> schemas,
        String dir,
        String name
      ) record) async {
    final (port, schemas, dir, name) = record;

    final rx = ReceivePort();
    final db = Isar.open(schemas: schemas, directory: dir, name: name);
    port.send(rx.sendPort);

    await for (final List<T> e in rx) {
      db.write((i) => db.collection<J, T>().putAll(e));
    }
  }

  @override
  Future<void> listenStatus(void Function(int p1) f) async {
    if (_status != null) {
      await _status!.cancel();

      _status = _instance
          .collection<J, T>()
          .watchLazy(fireImmediately: true)
          .listen((_) {
        f(_instance.collection<J, T>().count());
      });

      return;
    }

    _rx = ReceivePort("Loader(Port): ${_instance.directory}/${_instance.name}");
    _isolate = await Isolate.spawn(
      _startIsolate<T, J>,
      (_rx.sendPort, _schemas, _instance.directory, _instance.name),
      debugName: "Loader: ${_instance.directory}/${_instance.name}",
    );

    _isolateEvents = _rx.asBroadcastStream();

    _send = await _isolateEvents.first;

    if (_disposeBeforeListen) {
      _isolate.kill();
      _rx.close();
      return;
    }

    _status = _instance
        .collection<J, T>()
        .watchLazy(fireImmediately: true)
        .listen((_) {
      f(_instance.collection<J, T>().count());
    });

    if (_disposeBeforeListen) {
      _status!.cancel();
      _isolate.kill();
      _rx.close();
      return;
    }
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
    if (_status == null) {
      _disposeBeforeListen = true;
      return;
    }

    _status?.cancel();
    _isolate.kill();
    _rx.close();
  }

  @override
  void send(List<T> l) {
    _send.send(l);
  }
}

// class CellLoader<T extends Cell> implements DataLoader<T> {
//   final Isar _instance;
//   T Function(T)? _transform;
//   StreamSubscription<void>? _status;

//   @override
//   final IndexCellTokenizer<T> tokenizer;

//   @override
//   void dispose() {
//     _status?.cancel();
//   }

//   void _throwOnDifferentToken(SourceToken other) {
//     if (!tokenizer.sourceTokenMatches(other)) {
//       throw "Source differs:\nWant ${tokenizer._sourceToken}, but got $other";
//     }
//   }

//   @override
//   Iterable<T> getMany(Iterable<DataToken> tokens) sync* {
//     assert(_status != null);
//     for (final e in tokens) {
//       _throwOnDifferentToken(e.originalSource);

//       final cell = _instance.collection<T>().getSync(e.data)!;

//       yield _transform != null ? _transform!(cell) : cell;
//     }
//   }

//   @override
//   T? getSingle(DataToken token) {
//     assert(_status != null);

//     _throwOnDifferentToken(token.originalSource);

//     final cell = _instance.collection<T>().getSync(token.data);

//     return cell == null
//         ? cell
//         : _transform != null
//             ? _transform!(cell)
//             : cell;
//   }

//   @override
//   void listenStatus(void Function(int p1) f) {
//     assert(_status == null);
//     if (_status != null) {
//       return;
//     }

//     _status =
//         _instance.collection<T>().watchLazy(fireImmediately: true).listen((_) {
//       f(_instance.collection<T>().countSync());
//     });
//   }

//   @override
//   void transformData(T Function(T p1) f) {
//     assert(_status == null);

//     _transform = f;
//   }

//   CellLoader(this.tokenizer, {required Isar instance}) : _instance = instance;
// }

// class IndexCellTokenizer<T extends Cell> implements Tokenizer<T> {
//   final SourceToken _sourceToken;

//   @override
//   bool sourceTokenMatches(SourceToken other) {
//     return _sourceToken == other;
//   }

//   @override
//   Iterable<DataToken> tokenForMany(Iterable<T> data) sync* {
//     for (final e in data) {
//       yield DataToken(e.isarId!, _sourceToken);
//     }
//   }

//   @override
//   DataToken tokenForSingle(T data) {
//     return DataToken(data.isarId!, _sourceToken);
//   }

//   const IndexCellTokenizer(this._sourceToken);
// }
