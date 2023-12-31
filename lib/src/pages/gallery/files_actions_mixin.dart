// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'files.dart';

mixin _FilesActionsMixin on State<GalleryFiles> {
  Future<void> _deleteDialog(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    return Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(selected.length == 1
                  ? "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.first.name}"
                  : "${AppLocalizations.of(context)!.tagDeleteDialogTitle}"
                      " ${selected.length}"
                      " ${AppLocalizations.of(context)!.itemPlural}"),
              content:
                  Text(AppLocalizations.of(context)!.youCanRestoreFromTrash),
              actions: [
                TextButton(
                    onPressed: () {
                      PlatformFunctions.addToTrash(
                          selected.map((e) => e.originalUri).toList());
                      StatisticsGallery.addDeleted(selected.length);
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.yes)),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.no))
              ],
            );
          },
        ));
  }

  GridAction<SystemGalleryDirectoryFile> _restoreFromTrash() {
    return GridAction(
      Icons.restore_from_trash,
      (selected) {
        PlatformFunctions.removeFromTrash(
            selected.map((e) => e.originalUri).toList());
      },
      false,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _bulkRename() {
    return GridAction(
      Icons.edit,
      (selected) {
        _changeName(context, selected);
      },
      false,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _saveTagsAction(GalleryPlug plug) {
    return GridAction(
      Icons.tag_rounded,
      (selected) {
        _saveTags(context, selected, plug);
      },
      true,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _addToFavoritesAction(
      SystemGalleryDirectoryFile? f, GalleryPlug plug) {
    final isFavorites = f != null && f.isFavorite;

    return GridAction(
        isFavorites ? Icons.star_rounded : Icons.star_border_rounded,
        (selected) {
      _favoriteOrUnfavorite(context, selected, plug);
    }, false,
        color: isFavorites ? Colors.yellow.shade900 : null,
        animate: f != null,
        play: !isFavorites);
  }

  GridAction<SystemGalleryDirectoryFile> _setFavoritesThumbnailAction() {
    return GridAction(Icons.image_outlined, (selected) {
      MiscSettings.setFavoritesThumbId(selected.first.id);
      setState(() {});
    }, true, showOnlyWhenSingle: true);
  }

  GridAction<SystemGalleryDirectoryFile> _loadVideoThumbnailAction(
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state) {
    return GridAction(
      Icons.broken_image_outlined,
      (selected) {
        loadNetworkThumb(selected.first.name, selected.first.id).then((value) {
          try {
            setState(() {});
          } catch (_) {}

          state.gridKey.currentState?.imageViewKey.currentState
              ?.refreshPalette();
        });
      },
      true,
      showOnlyWhenSingle: true,
      onLongPress: (selected) {
        PlatformFunctions.deleteCachedThumbs([selected.first.id], true);

        final t = selected.first.getCellData(false, context: context).thumb;
        t?.evict();

        final deleted = PinnedThumbnail.delete(selected.first.id);

        if (t != null) {
          PaintingBinding.instance.imageCache.evict(t, includeLive: true);
        }

        if (deleted) {
          try {
            setState(() {});
          } catch (_) {}

          state.gridKey.currentState?.imageViewKey.currentState
              ?.refreshPalette();
        }
      },
    );
  }

  GridAction<SystemGalleryDirectoryFile> _deleteAction() {
    return GridAction(
      Icons.delete,
      (selected) {
        _deleteDialog(context, selected);
      },
      false,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _copyAction(
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    return GridAction(
      Icons.copy,
      (selected) {
        _moveOrCopy(context, selected, false, state, plug);
      },
      false,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _moveAction(
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    return GridAction(
      Icons.forward,
      (selected) {
        _moveOrCopy(context, selected, true, state, plug);
      },
      false,
    );
  }

  GridAction<SystemGalleryDirectoryFile> _chooseAction() {
    return GridAction(
      Icons.check,
      (selected) {
        widget.callback!(selected.first);
        if (widget.callback!.returnBack) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        }
      },
      false,
    );
  }

  void _moveOrCopy(
      BuildContext context,
      List<SystemGalleryDirectoryFile> selected,
      bool move,
      GridSkeletonStateFilter<SystemGalleryDirectoryFile> state,
      GalleryPlug plug) {
    state.gridKey.currentState?.imageViewKey.currentState?.wrapNotifiersKey
        .currentState
        ?.pauseVideo();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return WrapGridPage<SystemGalleryDirectory>(
            scaffoldKey: GlobalKey(),
            child: GalleryDirectories(
              showBackButton: true,
              procPop: (_) {},
              callback: CallbackDescription(
                  move
                      ? AppLocalizations.of(context)!.chooseMoveDestination
                      : AppLocalizations.of(context)!.chooseCopyDestination,
                  (chosen, newDir) {
                if (chosen == null && newDir == null) {
                  throw "both are empty";
                }

                if (chosen != null && chosen.bucketId == widget.bucketId) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(move
                          ? AppLocalizations.of(context)!.cantMoveSameDest
                          : AppLocalizations.of(context)!.cantCopySameDest)));
                  return Future.value();
                }

                if (chosen?.bucketId == "favorites") {
                  _favoriteOrUnfavorite(context, selected, plug);
                } else if (chosen?.bucketId == "trash") {
                  if (!move) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                      "Can't copy files to the trash. Use move.", // TODO: change
                    )));
                    return Future.value();
                  }

                  return _deleteDialog(context, selected);
                } else {
                  PlatformFunctions.copyMoveFiles(
                      chosen?.relativeLoc, chosen?.volumeName, selected,
                      move: move, newDir: newDir);

                  if (move) {
                    StatisticsGallery.addMoved(selected.length);
                  } else {
                    StatisticsGallery.addCopied(selected.length);
                  }
                }

                return Future.value();
              },
                  preview: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: CopyMovePreview(
                      files: selected,
                      size: 52,
                    ),
                  ),
                  joinable: false),
            ));
      },
    )).then((value) => state.gridKey.currentState?.imageViewKey.currentState
        ?.wrapNotifiersKey.currentState
        ?.unpauseVideo());
  }

  void _favoriteOrUnfavorite(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, GalleryPlug plug) {
    final toDelete = <int>[];
    final toAdd = <int>[];

    for (final fav in selected) {
      if (fav.isFavorite) {
        toDelete.add(fav.id);
      } else {
        toAdd.add(fav.id);
      }
    }

    if (toAdd.isNotEmpty) {
      FavoriteMedia.addAll(toAdd);
    }

    plug.notify(null);

    if (toDelete.isNotEmpty) {
      FavoriteMedia.deleteAll(toDelete);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Deleted from favorites"),
        action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              FavoriteMedia.addAll(toDelete);

              plug.notify(null);
            }),
      ));
    }
  }

  void _saveTags(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, GalleryPlug plug) async {
    if (_isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.tagSavingInProgress)));
      return;
    }
    _isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
        "${AppLocalizations.of(context)!.savingTagsSaving}"
            " ${selected.length == 1 ? '1 ${AppLocalizations.of(context)!.tagSingular}' : '${selected.length} ${AppLocalizations.of(context)!.tagPlural}'}",
        savingTagsNotifId,
        "Saving tags",
        AppLocalizations.of(context)!.savingTags);
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (PostTags.g.getTagsPost(elem.name).isEmpty) {
        await PostTags.g.getOnlineAndSaveTags(elem.name);
      }
    }
    notifi.done();
    plug.notify(null);
    _isSavingTags = false;
  }

  void _changeName(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    if (selected.isEmpty) {
      return;
    }
    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.bulkRenameTitle),
              content: TextFormField(
                autofocus: true,
                initialValue: "*",
                autovalidateMode: AutovalidateMode.always,
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.valueIsNull;
                  }
                  if (value.isEmpty) {
                    return AppLocalizations.of(context)!.newNameShouldntBeEmpty;
                  }

                  if (!value.contains("*")) {
                    return AppLocalizations.of(context)!
                        .newNameShouldIncludeOneStar;
                  }

                  return null;
                },
                onFieldSubmitted: (value) async {
                  if (value.isEmpty) {
                    return;
                  }
                  final idx = value.indexOf("*");
                  if (idx == -1) {
                    return;
                  }

                  final matchBefore = value.substring(0, idx);

                  for (final (i, e) in selected.indexed) {
                    PlatformFunctions.rename(
                        e.originalUri, "$matchBefore${e.name}",
                        notify: i == selected.length - 1);
                  }

                  Navigator.pop(context);
                },
              ),
            );
          },
        ));
  }
}
