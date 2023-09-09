// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../booru/interface.dart';
import '../db/state_restoration.dart';
import '../keybinds/keybinds.dart';
import '../widgets/autocomplete_widget.dart';
import '../widgets/single_post.dart';
import '../widgets/tags_widget.dart';

class TagsPage extends StatefulWidget {
  final TagManager tagManager;
  final bool popSenitel;
  final bool fromGallery;

  const TagsPage(
      {super.key,
      required this.tagManager,
      required this.popSenitel,
      required this.fromGallery});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final booru = BooruAPI.fromSettings();

  final focus = FocusNode();
  final excludedFocus = FocusNode();
  final singlePostFocus = FocusNode();

  final textController = TextEditingController();
  final excludedTagsTextController = TextEditingController();

  final skeletonState = SkeletonState(kTagsDrawerIndex);

  late final StreamSubscription<void> _lastTagsWatcher;

  List<Tag> _excludedTags = [];
  List<Tag> _lastTags = [];

  String searchHighlight = "";
  String excludedHighlight = "";

  AnimationController? replaceController;
  AnimationController? deleteAllExcludedController;
  AnimationController? deleteAllController;

  bool recentTagsExpanded = true;
  bool excludedTagsExpanded = true;

  @override
  void initState() {
    focus.addListener(() {
      if (!focus.hasFocus) {
        searchHighlight = "";
        skeletonState.mainFocus.requestFocus();
      }
    });

    excludedFocus.addListener(() {
      if (!excludedFocus.hasFocus) {
        excludedHighlight = "";
        skeletonState.mainFocus.requestFocus();
      }
    });

    singlePostFocus.addListener(() {
      if (!singlePostFocus.hasFocus) {
        skeletonState.mainFocus.requestFocus();
      }
    });

    super.initState();
    _lastTagsWatcher = widget.tagManager.watch(true, () {
      _lastTags = widget.tagManager.latest.get();
      _excludedTags = widget.tagManager.excluded.get();

      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    excludedTagsTextController.dispose();
    _lastTagsWatcher.cancel();
    focus.dispose();

    excludedFocus.dispose();
    singlePostFocus.dispose();
    skeletonState.dispose();

    booru.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeleton(
      context,
      AppLocalizations.of(context)!.tagsInfoPage,
      skeletonState,
      additionalBindings: {
        SingleActivatorDescription(
            AppLocalizations.of(context)!.selectSuggestion,
            const SingleActivator(LogicalKeyboardKey.enter, shift: true)): () {
          if (focus.hasFocus) {
            if (searchHighlight.isNotEmpty) {
              widget.tagManager.onTagPressed(
                  context, Tag.string(tag: searchHighlight), booru.booru, true);
            }
          } else if (excludedFocus.hasFocus) {
            if (excludedHighlight.isNotEmpty) {
              widget.tagManager.excluded
                  .add(Tag.string(tag: excludedHighlight));
              excludedTagsTextController.text = "";
            }
          }
        },
        SingleActivatorDescription(AppLocalizations.of(context)!.focusSearch,
            const SingleActivator(LogicalKeyboardKey.keyF, control: true)): () {
          if (focus.hasFocus) {
            focus.unfocus();
          } else {
            focus.requestFocus();
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.focusSinglePost,
            const SingleActivator(LogicalKeyboardKey.keyF, alt: true)): () {
          if (singlePostFocus.hasFocus) {
            singlePostFocus.unfocus();
          } else {
            singlePostFocus.requestFocus();
          }
        },
        SingleActivatorDescription(
            AppLocalizations.of(context)!.focusExcludedSearch,
            const SingleActivator(LogicalKeyboardKey.keyF, shift: true)): () {
          if (excludedFocus.hasFocus) {
            if (replaceController != null) {
              replaceController!
                  .reverse(from: 1)
                  .then((value) => excludedFocus.unfocus());
            } else {
              excludedFocus.unfocus();
            }
          } else {
            if (replaceController != null) {
              replaceController!
                  .forward(from: 0)
                  .then((value) => excludedFocus.requestFocus());
            } else {
              excludedFocus.requestFocus();
            }
          }
        },
      },
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: SinglePost(
            focus: singlePostFocus,
            tagManager: widget.tagManager,
          ),
        ),
        ExpansionPanelList(
          elevation: 0,
          dividerColor: Theme.of(context).colorScheme.background,
          expansionCallback: (panelIndex, isExpanded) => switch (panelIndex) {
            0 => setState(() => recentTagsExpanded = !recentTagsExpanded),
            1 => setState(() => excludedTagsExpanded = !excludedTagsExpanded),
            int() => throw "out of range",
          },
          children: [
            ExpansionPanel(
                isExpanded: recentTagsExpanded,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text(AppLocalizations.of(context)!.recentTagsTitle),
                    trailing: IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              DialogRoute(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .tagsDeletionDialogTitle),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .no)),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            if (deleteAllController != null) {
                                              deleteAllController!
                                                  .forward(from: 0)
                                                  .then((value) {
                                                widget.tagManager.latest
                                                    .clear();
                                                if (deleteAllController !=
                                                    null) {
                                                  deleteAllController!
                                                      .reverse(from: 1);
                                                }
                                              });
                                            }
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .yes))
                                    ],
                                  );
                                },
                              ));
                        },
                        icon: const Icon(Icons.delete)),
                  );
                },
                body: TagsWidget(
                    tags: _lastTags,
                    deleteTag: (t) {
                      if (deleteAllController != null) {
                        deleteAllController!.forward(from: 0).then((value) {
                          widget.tagManager.latest.delete(t);
                          if (deleteAllController != null) {
                            deleteAllController!.reverse(from: 1);
                          }
                        });
                      } else {
                        widget.tagManager.latest.delete(t);
                      }
                    },
                    onPress: (t) => widget.tagManager
                        .onTagPressed(context, t, booru.booru, true)).animate(
                    onInit: (controller) => deleteAllController = controller,
                    effects: [
                      FadeEffect(begin: 1, end: 0, duration: 200.milliseconds)
                    ],
                    autoPlay: false)),
            ExpansionPanel(
                isExpanded: excludedTagsExpanded,
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title:
                        Text(AppLocalizations.of(context)!.excludedTagsTitle),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (replaceController != null) {
                          replaceController!.forward(from: 0);
                        }
                      },
                    ),
                  ).animate(
                      onInit: (controller) => replaceController = controller,
                      effects: [
                        FadeEffect(
                            begin: 1, end: 0, duration: 200.milliseconds),
                        SwapEffect(
                            builder: (_, __) => ListTile(
                                  title: autocompleteWidget(
                                      excludedTagsTextController, (s) {
                                    excludedHighlight = s;
                                  },
                                      widget.tagManager.excluded.add,
                                      () => focus.requestFocus(),
                                      booru.completeTag,
                                      excludedFocus,
                                      submitOnPress: true,
                                      showSearch: true),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      if (replaceController != null) {
                                        replaceController!.reverse(from: 1);
                                      }
                                    },
                                  ),
                                ).animate().fadeIn()),
                      ],
                      autoPlay: false);
                },
                body: TagsWidget(
                        redBackground: true,
                        tags: _excludedTags,
                        deleteTag: (t) {
                          if (deleteAllExcludedController != null) {
                            deleteAllExcludedController!
                                .forward(from: 0)
                                .then((value) {
                              widget.tagManager.excluded.delete(t);
                              if (deleteAllExcludedController != null) {
                                deleteAllExcludedController!.reverse(from: 1);
                              }
                            });
                          } else {
                            widget.tagManager.excluded.delete(t);
                          }
                        },
                        onPress: (t) {})
                    .animate(
                        onInit: (controller) =>
                            deleteAllExcludedController = controller,
                        effects: const [FadeEffect(begin: 1, end: 0)],
                        autoPlay: false))
          ],
        ),
      ],
      popSenitel: widget.popSenitel,
      overrideChooseRoute: widget.fromGallery
          ? (route, original) {
              if (route == kGalleryDrawerIndex) {
                Navigator.pop(context);
                Navigator.pop(context);
              } else {
                original();
              }
            }
          : null,
    );
  }
}
