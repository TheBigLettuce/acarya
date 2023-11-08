// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/interfaces/cell.dart';

import '../../grid_metadata.dart';

class NotesLayout<T extends Cell> extends StatefulWidget {
  final GridColumn columns;

  final GridMetadata<T> metadata;

  final T Function(int) getOriginalCell;

  const NotesLayout({
    super.key,
    required this.columns,
    required this.getOriginalCell,
    required this.metadata,
  });

  @override
  State<NotesLayout> createState() => _NotesLayoutState();
}

class _NotesLayoutState extends State<NotesLayout> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
