// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/paging_isar_loader.dart';
import 'package:gallery/src/db/schemas/note.dart';
import 'package:gallery/src/db/schemas/note_gallery.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:gallery/src/widgets/skeletons/make_grid_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:octo_image/octo_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

import '../db/schemas/system_gallery_directory.dart';
import '../db/schemas/system_gallery_directory_file.dart';
import '../interfaces/cell.dart';
import '../widgets/grid/wrap_grid_page.dart';

const kNoteLoadCount = 30;

class _NotePageContainer<T extends Cell> {
  final state = GridSkeletonState<T>();
  final PagingIsarLoader<T> notes;
  final List<T> Function(String text) filterFnc;
  final NoteInterface<T> noteInterface;
  final List<GridAction<T>> addActions;
  final List<String> Function(T cell) getText;

  Iterable<Widget> filter(BuildContext context, SearchController controller) {
    return filterFnc(controller.text).map((e1) => ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                final overlayColor =
                    Theme.of(context).colorScheme.background.withOpacity(0.5);

                return ImageView<T>(
                    updateTagScrollPos: (_, __) {},
                    cellCount: 1,
                    scrollUntill: (_) {},
                    startingCell: 0,
                    onExit: () {},
                    onEmptyNotes: () {
                      WidgetsBinding.instance
                          .scheduleFrameCallback((timeStamp) {
                        Navigator.pop(context);
                      });
                    },
                    noteInterface: noteInterface,
                    getCell: (idx) => e1,
                    onNearEnd: null,
                    focusMain: () => state.mainFocus,
                    systemOverlayRestoreColor: overlayColor);
              },
            ));
          },
          title: Container(
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: OctoImage(
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                image: e1.getCellData(false, context: context).thumb!),
          ),
        ).animate().fadeIn());
  }

  Widget widget(BuildContext context) => makeGridSkeleton<T>(
      context,
      state,
      CallbackGrid<T>(
        key: state.gridKey,
        getCell: notes.get,
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        immutable: false,
        onBack: () {
          Navigator.pop(context);
        },
        systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
        hasReachedEnd: notes.reachedEnd,
        selectionGlue: SelectionGlue.empty(context),
        mainFocus: state.mainFocus,
        refresh: notes.refresh,
        noteInterface: noteInterface,
        addIconsImage: (_) => addActions,
        initalCellCount: notes.count(),
        loadNext: notes.next,
        description: GridDescription<T>([],
            keybindsDescription: "Notes page",
            showAppBar: false,
            layout: NoteLayout<T>(GridColumn.three, getText)),
      ),
      canPop: true);

  void dispose() {
    state.dispose();
    notes.dispose(force: true);
  }

  _NotePageContainer(List<CollectionSchema> schemas, this.noteInterface,
      {required Iterable<T> Function(int) loadNext,
      required this.filterFnc,
      this.addActions = const [],
      required this.getText})
      : notes = PagingIsarLoader<T>(schemas, loadNext);
}

class NotesPage extends StatefulWidget {
  final CallbackDescriptionNested? callback;

  const NotesPage({super.key, this.callback});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  final searchController = SearchController();
  late final tabController = TabController(length: 2, vsync: this);

  late final StreamSubscription<void> booruNotesWatcher;
  late final StreamSubscription<void> galleryNotesWatcher;

  late final _NotePageContainer<NoteBooru> booruContainer =
      _NotePageContainer<NoteBooru>(
          [NoteBooruSchema],
          NoteBooru.interfaceSelf(() {
            booruContainer.state.gridKey.currentState?.refresh(() =>
                booruContainer.notes.loadUntil(booruContainer.notes.count()));
          }),
          loadNext: (count) => Dbs.g.blacklisted.noteBoorus
              .where()
              .offset(count)
              .limit(kNoteLoadCount)
              .findAllSync(),
          filterFnc: (text) {
            return Dbs.g.blacklisted.noteBoorus
                .filter()
                .textElementContains(text, caseSensitive: false)
                .limit(15)
                .findAllSync();
          },
          getText: (cell) => cell.currentText());
  late final _NotePageContainer<NoteGallery> galleryContainer =
      _NotePageContainer<NoteGallery>(
          [NoteGallerySchema],
          NoteGallery.interfaceSelf(() {
            galleryContainer.state.gridKey.currentState?.refresh(() =>
                galleryContainer.notes
                    .loadUntil(galleryContainer.notes.count()));
          }),
          loadNext: (count) => Dbs.g.main.noteGallerys
              .where()
              .offset(count)
              .limit(kNoteLoadCount)
              .findAllSync(),
          filterFnc: (text) {
            return Dbs.g.main.noteGallerys
                .filter()
                .textElementContains(text, caseSensitive: false)
                .limit(15)
                .findAllSync();
          },
          addActions: widget.callback != null
              ? [
                  GridAction(
                    Icons.check,
                    (selected) {
                      final note = selected.first;

                      widget.callback!(SystemGalleryDirectoryFile(
                          id: note.id,
                          bucketId: "",
                          name: "",
                          isVideo: note.isVideo,
                          isGif: note.isGif,
                          size: 0,
                          height: note.height,
                          notesFlat: "",
                          width: note.width,
                          isOriginal: false,
                          lastModified: 0,
                          originalUri: note.originalUri));
                    },
                    false,
                  )
                ]
              : [
                  GridAction(
                    Icons.forward,
                    (selected) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return WrappedGridPage<SystemGalleryDirectory>(
                            scaffoldKey: GlobalKey(),
                            f: (glue) => GalleryDirectories(
                                  glue: glue,
                                  procPop: (p) {},
                                  nestedCallback: CallbackDescriptionNested(
                                      "Choose file", (chosen) async {
                                    final s = selected.first;
                                    final data = chosen.getCellData(false,
                                        context: context);
                                    final colors = await PaletteGenerator
                                        .fromImageProvider(data.thumb!);

                                    NoteGallery.add(chosen.id,
                                        text: s.text,
                                        height: chosen.height,
                                        width: chosen.width,
                                        backgroundColor:
                                            colors.dominantColor?.color,
                                        textColor:
                                            colors.dominantColor?.bodyTextColor,
                                        isVideo: chosen.isVideo,
                                        isGif: chosen.isGif,
                                        originalUri: chosen.originalUri);
                                    NoteGallery.removeAll(s.id);

                                    galleryContainer.state.gridKey.currentState
                                        ?.refresh();
                                  }, returnBack: true),
                                ));
                      }));
                    },
                    false,
                  )
                ],
          getText: (cell) => cell.currentText());

  @override
  void initState() {
    booruNotesWatcher = Dbs.g.blacklisted.noteBoorus.watchLazy().listen((_) {
      setState(() {});
    });
    galleryNotesWatcher = Dbs.g.main.noteGallerys.watchLazy().listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    booruContainer.dispose();
    galleryContainer.dispose();

    searchController.dispose();
    tabController.dispose();

    booruNotesWatcher.cancel();
    galleryNotesWatcher.cancel();

    super.dispose();
  }

  Tab _makeTab(String title, int length) => Tab(
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Badge.count(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              count: length,
            ),
          )
        ],
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          SearchAnchor(
            searchController: searchController,
            builder: (context, controller) {
              return IconButton(
                  onPressed: () {
                    controller.openView();
                  },
                  icon: const Icon(Icons.search_rounded));
            },
            viewBuilder: (widgets) {
              final w = widgets.toList();

              if (w.isEmpty) {
                return const EmptyWidget();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      "Showing ${w.length} results", // TODO: change
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Expanded(child: ListView(children: w))
                ],
              );
            },
            viewHintText: "Search", // TOOD: change
            suggestionsBuilder: (context, controller) {
              if (controller.text.isEmpty) {
                return [];
              }

              return tabController.index == 1 || widget.callback != null
                  ? galleryContainer.filter(context, controller)
                  : booruContainer.filter(context, controller);
            },
          )
        ],
        title: Text("Notes"),
        bottom: widget.callback != null
            ? CopyMovePreview.hintWidget(context, widget.callback!.description)
            : TabBar(controller: tabController, tabs: [
                _makeTab(AppLocalizations.of(context)!.booruLabel,
                    Dbs.g.blacklisted.noteBoorus.countSync()),
                _makeTab(AppLocalizations.of(context)!.galleryLabel,
                    Dbs.g.main.noteGallerys.countSync())
              ]),
      ),
      body: widget.callback != null
          ? galleryContainer.widget(context)
          : TabBarView(controller: tabController, children: [
              booruContainer.widget(context),
              galleryContainer.widget(context)
            ]),
    );
  }
}
