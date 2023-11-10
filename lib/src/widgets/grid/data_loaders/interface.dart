import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/db/booru_tagging.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/interfaces/tags.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import '../../../db/schemas/post.dart';

const kAndroidGalleryLoaderKey = 0;
const kMainGridLoaderKey = 1;

/// Load data in a background isolate.
/// Depends on the ability of writing to the source on a different Isolate.
sealed class BackgroundDataLoader<T, J> {
  /// Isolate associated with the loader.
  /// [listenStatus] should be called before accessing [isolate].
  Isolate get isolate;

  Future<void> init();

  /// Begin listening for the events in the source.
  /// After the call to [listenStatus] complete, [isolate], [send]
  /// and [dispose] become available.
  /// Trying to access [listenStatus], [send] or [dispose] before [listenStatus]'s future
  /// complete is undefined behaviour.
  void listenStatus(void Function(int) f);

  /// Apply transformations to the data before it is emitted by [getSingle].
  void transformData(T Function(T)? f);

  /// Return the single piece of data.
  /// This is used in the widget builders.
  T? getSingle(J token);

  /// Send the data for the insertion.
  /// [l] should be immutable, otherwise there is not much
  /// benefit in using [BackgroundDataLoader].
  /// [listenStatus] should be called before calling [send].
  void send(ControlMessage m);

  /// Shutdown the loader. After the call to [dispose],
  /// the instance is invalid and should not be used.
  /// [listenStatus] should be called before calling [dispose].
  void dispose();

  LoaderStateController get state;

  const BackgroundDataLoader();
}

enum LoaderState { loading, idle }

abstract class LoaderStateController {
  LoaderState get currentState;

  void listen(void Function() f);

  void next();
  void reset();

  void dispose();
}

class DummyBackgroundLoader<T, J> implements BackgroundDataLoader<T, J> {
  @override
  void dispose() {}

  @override
  T? getSingle(J token) => null;

  @override
  Isolate get isolate => throw UnimplementedError();

  @override
  void listenStatus(void Function(int p1) f) {}

  @override
  Future<void> init() => Future.value();

  @override
  void send(ControlMessage m) {}

  @override
  void transformData(T Function(T p1)? f) {}

  @override
  LoaderStateController get state => const DummyLoaderStateController();
}

class DummyLoaderStateController implements LoaderStateController {
  @override
  LoaderState get currentState => LoaderState.idle;

  @override
  void dispose() {}

  @override
  void listen(void Function() f) {}

  @override
  void next() {}

  @override
  void reset() {}

  const DummyLoaderStateController();
}

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

class CellLoaderStateController<T extends Cell, I>
    implements LoaderStateController {
  final Stream _events;
  final void Function(CellLoaderStateController<T, I>) onNext;
  final void Function(CellLoaderStateController<T, I>) onReset;

  LoaderState _state = LoaderState.idle;
  StreamSubscription? _currentSubscription;

  @override
  LoaderState get currentState => _state;

  @mustCallSuper
  @override
  void listen(f) {
    if (_currentSubscription != null) {
      _currentSubscription?.cancel();
    }

    _currentSubscription = _events.listen((event) {
      event as LoaderState;

      if (event == currentState) {
        return;
      }

      _state = event;

      f();
    });
  }

  @mustCallSuper
  @override
  void next() {
    if (currentState == LoaderState.idle) {
      onNext(this);
    }
  }

  @mustCallSuper
  @override
  void reset() {
    if (currentState == LoaderState.idle) {
      onReset(this);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _currentSubscription?.cancel();
  }

  static void _doNothing(CellLoaderStateController _) {}

  CellLoaderStateController(BackgroundCellLoader<T, I> loader,
      {this.onNext = _doNothing, this.onReset = _doNothing})
      : _events = loader._isolateEvents;
}

class BooruAPILoaderStateController implements LoaderStateController {
  final Stream _events;
  final SendPort _send;

  final BooruAPI api;
  final BooruTagging excluded;
  final String tags;

  LoaderState _state = LoaderState.idle;
  StreamSubscription? _currentSubscription;
  void Function()? _notify;

  int? currentLast;

  bool end = false;

  BooruAPILoaderStateController(BackgroundCellLoader<Post, String> loader,
      this.api, this.excluded, this.tags, int? lastId)
      : _events = loader._isolateEvents,
        currentLast = lastId,
        _send = loader._send;

  void _stateChange(LoaderState s) {
    _state = s;
    currentLast = null;
    _notify?.call();
  }

  @override
  LoaderState get currentState => _state;

  @mustCallSuper
  @override
  void listen(f) {
    if (_currentSubscription != null) {
      _currentSubscription?.cancel();
    }

    _currentSubscription = _events.listen((event) {
      event as LoaderState;

      if (event == currentState) {
        return;
      }

      _state = event;

      f();
    });

    _notify = f;
  }

  void _sendPosts((List<Post>, int?) value) {
    final last = value.$1.lastOrNull;
    if (last == null) {
      _stateChange(LoaderState.idle);
      end = true;
      return;
    }

    if (value.$2 != null) {
      if (value.$2! > last.postId) {
        currentLast = value.$2;
      } else {
        currentLast = last.postId;
      }
    } else {
      currentLast = last.postId;
    }

    _send.send(Data<Post>(value.$1, end: true));
  }

  @mustCallSuper
  @override
  void next() {
    if (end) {
      return;
    }

    if (currentState == LoaderState.idle && _currentSubscription != null) {
      final last = currentLast;

      _stateChange(LoaderState.loading);

      api.fromPost(last!, tags, excluded).then(_sendPosts);
    }
  }

  @mustCallSuper
  @override
  void reset() {
    if (currentState == LoaderState.idle && _currentSubscription != null) {
      _stateChange(LoaderState.loading);
      _send.send(const Reset(true));
      end = false;
      api.page(0, tags, excluded).then(_sendPosts);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _currentSubscription?.cancel();
    _currentSubscription = null;
    _notify = null;
    currentLast = null;
    end = false;
    // api.close();
  }
}

@immutable
sealed class ControlMessage {
  const ControlMessage();
}

@immutable
class Reset extends ControlMessage {
  final bool silent;

  const Reset([this.silent = false]);
}

@immutable
class Data<T extends Cell> extends ControlMessage {
  final List<T> l;
  final bool end;

  const Data(this.l, {this.end = false});
}
