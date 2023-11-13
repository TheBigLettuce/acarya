// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/interfaces/filtering/sorting_mode.dart';
import 'package:meta/meta.dart';

const kAndroidGalleryLoaderKey = 0;
const kMainGridLoaderKey = 1;
const kAndroidFilesPrimaryLoaderKey = 2;
const kAndroidFilesSecondaryLoaderKey = 3;

/// Load data in a background isolate.
/// Depends on the ability of writing to the source on a different Isolate.
abstract interface class BackgroundDataLoader<T, J> {
  /// Isolate associated with the loader.
  /// [listenStatus] should be called before accessing [isolate].
  Isolate get isolate;

  DataTransformer? get transformer;

  Future<void> init();

  /// Begin listening for the events in the source.
  /// After the call to [listenStatus] complete, [isolate], [send]
  /// and [dispose] become available.
  /// Trying to access [listenStatus], [send] or [dispose] before [listenStatus]'s future
  /// complete is undefined behaviour.
  void listenStatus(void Function(int) f);

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

abstract interface class DataTransformer<T, J> {
  Set<FilteringMode> get capabilityFiltering;
  Set<SortingMode> get capabilitySorting;

  FilteringMode get currentFiltering;
  SortingMode get currentSoring;

  T transformCell(T elem);
  void transformStatusCallback(void Function(int count) f);

  void setSortingMode(SortingMode sorting);
  void setFilteringMode(FilteringMode filtering);

  void reset();

  const DataTransformer();
}

enum LoaderState { loading, idle }

abstract interface class LoaderStateController {
  LoaderState get currentState;

  void listen(void Function() f);

  void next();
  void reset();

  void dispose();
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
class Data<T> extends ControlMessage {
  final List<T> l;
  final bool end;

  const Data(this.l, {this.end = false});
}

@immutable
class Poll extends ControlMessage {
  const Poll();
}

@immutable
class Binary extends ControlMessage {
  final int type;
  final ByteData data;

  const Binary(this.data, {required this.type});
}

@immutable
class ChangeContext extends ControlMessage {
  final int contextStage;
  final dynamic data;

  const ChangeContext(this.contextStage, this.data);
}
