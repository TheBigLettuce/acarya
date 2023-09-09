// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/contentable.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';

part 'blacklisted_directory.g.dart';

@collection
class BlacklistedDirectory implements Cell {
  @override
  Id? isarId;

  @Index(unique: true, replace: true)
  String bucketId;
  @Index()
  final String name;

  @override
  @ignore
  List<Widget>? Function(BuildContext context) get addButtons => (_) => null;

  @override
  @ignore
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (_, __, ___) => null;

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay() {
    throw UnimplementedError();
  }

  @override
  String fileDownloadUrl() {
    throw UnimplementedError();
  }

  @override
  CellData getCellData(bool isList, {BuildContext? context}) =>
      CellData(thumb: null, name: name, stickers: []);

  BlacklistedDirectory(this.bucketId, this.name);
}
