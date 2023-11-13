// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru_api/booru.dart';
import 'package:gallery/src/widgets/restart_widget.dart';

class TranslationNotes extends StatefulWidget {
  const TranslationNotes(
      {super.key, required this.booru, required this.postId});

  final int postId;
  final Booru booru;

  static Widget tile(
      BuildContext context, Color foregroundColor, int postId, Booru booru) {
    return ListTile(
      textColor: foregroundColor,
      title: Text("Has translations"),
      subtitle: Text("Tap to view"),
      onTap: () {
        Navigator.push(
            context,
            DialogRoute(
              context: context,
              builder: (context) {
                return TranslationNotes(
                  postId: postId,
                  booru: booru,
                );
              },
            ));
      },
    );
  }

  @override
  State<TranslationNotes> createState() => _TranslationNotesState();
}

class _TranslationNotesState extends State<TranslationNotes> {
  late final future = widget.booru
      .functions()
      .notes(RestartWidget.contextlessClient, widget.postId);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Translation"),
      content: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: snapshot.data!
                      .map((e) => ListTile(
                            title: Text(e),
                          ))
                      .toList(),
                ),
              );
            }

            return SizedBox.fromSize(
              size: const Size.square(42),
              child: const Center(child: CircularProgressIndicator()),
            );
          }),
    );
  }
}
