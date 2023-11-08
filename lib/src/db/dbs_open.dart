// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'initalize_db.dart';

abstract class DbsOpen {
  static Isar primaryGrid(Booru booru) {
    // final instance = Isar.get(schemas: [
    //   GridStateSchema,
    //   TagSchema,
    //   PostSchema,
    // ], name: booru.string);
    // if (instance != null) {
    //   return instance;
    // }

    return Isar.open(schemas: [
      GridStateSchema,
      TagSchema,
      PostSchema,
    ], directory: _dbs.directory, inspector: false, name: booru.string);
  }

  static Isar secondaryGrid({bool temporary = true}) {
    return Isar.open(
        schemas: [PostSchema],
        directory: temporary ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: _microsecSinceEpoch());
  }

  static Isar secondaryGridName(String name) {
    return Isar.open(
        schemas: [PostSchema],
        directory: _dbs.directory,
        inspector: false,
        name: name);
  }

  static Isar localTags() => Isar.open(
        schemas: [
          LocalTagsSchema,
          LocalTagDictionarySchema,
          DirectoryTagSchema
        ],
        directory: _dbs.directory,
        inspector: false,
        name: "localTags",
      );

  static Isar androidGalleryDirectories({bool? temporary}) => Isar.open(
        schemas: [SystemGalleryDirectorySchema],
        directory: temporary == true ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: temporary == true
            ? _microsecSinceEpoch()
            : "systemGalleryDirectories",
      );

  static Isar androidGalleryFiles() => Isar.open(
        schemas: [SystemGalleryDirectoryFileSchema],
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static Isar temporarySchemas(List<IsarGeneratedSchema> schemas) => Isar.open(
        schemas: schemas,
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static String _microsecSinceEpoch() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
