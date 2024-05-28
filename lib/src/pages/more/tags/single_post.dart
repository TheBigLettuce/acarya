// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";
import "package:qrscan/qrscan.dart";

class SinglePost extends StatefulWidget {
  const SinglePost({
    super.key,
    required this.tagManager,
    this.overrideLeading,
    required this.db,
  });

  final TagManager tagManager;
  final Widget? overrideLeading;

  final FavoritePostSourceService db;

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  late final Dio client;
  late final BooruAPI booruApi;

  final controller = TextEditingController();
  final menuController = MenuController();

  List<Widget> menuItems = [];
  bool inProcessLoading = false;

  AnimationController? arrowSpinningController;

  @override
  void initState() {
    super.initState();

    final booru = SettingsService.db().current.selectedBooru;
    client = BooruAPI.defaultClientForBooru(booru);
    booruApi = BooruAPI.fromEnum(booru, client, EmptyPageSaver());
  }

  @override
  void dispose() {
    arrowSpinningController = null;
    controller.dispose();
    client.close(force: true);

    super.dispose();
  }

  Future<void> _launch([Booru? replaceBooru, int? replaceId]) async {
    if (inProcessLoading) {
      return;
    }

    inProcessLoading = true;

    BooruAPI booru;
    if (replaceBooru != null) {
      booru = BooruAPI.fromEnum(replaceBooru, client, EmptyPageSaver());
    } else {
      booru = booruApi;
    }

    try {
      unawaited(arrowSpinningController?.repeat());

      final Post value;

      if (replaceId != null) {
        value = await booru.singlePost(replaceId);
      } else {
        final n = int.tryParse(controller.text);
        if (n == null) {
          throw AppLocalizations.of(context)!.notANumber(controller.text);
        }

        value = await booru.singlePost(n);
      }

      // final key = GlobalKey<ImageViewState>();

      // final favoritesWatcher = widget.db.watch((event) {
      //   key.currentState?.setState(() {});
      // });

      return ImageView.launchWrapped(
        // ignore: use_build_context_synchronously
        context,
        1,
        (__) => value.content(),
        // key: key,
        download: (_) => value.download(context),
      );
    } catch (e, trace) {
      try {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      } catch (_) {}

      log(
        "going to a post in single post",
        level: Level.SEVERE.value,
        error: e,
        stackTrace: trace,
      );
    }

    arrowSpinningController
      ?..stop()
      ..reverse();

    inProcessLoading = false;
  }

  Future<void> _tryClipboard() async {
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboard == null ||
          clipboard.text == null ||
          clipboard.text!.isEmpty) {
        return;
      }

      final numbers = RegExp(r"\d+")
          .allMatches(clipboard.text!)
          .map((e) => e.input.substring(e.start, e.end))
          .toList();
      if (numbers.isEmpty) {
        return;
      }

      if (numbers.length == 1) {
        controller.text = numbers.first;
        return;
      }

      setState(() {
        menuItems = numbers
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  controller.text = e;
                  menuController.close();
                },
              ),
            )
            .toList();
      });

      menuController.open();
    } catch (e, trace) {
      log(
        "clipboard button in single post",
        level: Level.WARNING.value,
        error: e,
        stackTrace: trace,
      );
    }
  }

  Future<void> _qrCode() async {
    final camera = await Permission.camera.request();

    if (!camera.isGranted) {
      return Navigator.push<void>(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.error),
              content: Text(
                AppLocalizations.of(context)!.cameraPermQrCodeErr,
              ),
            );
          },
        ),
      );
    } else {
      final value = await scan();
      if (value == null) {
        return;
      }

      if (RegExp("^[0-9]").hasMatch(value)) {
        controller.text = value;
      } else {
        try {
          final f = value.split("_");
          return _launch(Booru.fromPrefix(f[0]), int.parse(f[1]));
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuItems,
      controller: menuController,
      child: SearchBar(
        hintText: AppLocalizations.of(context)!.goPostHint,
        controller: controller,
        // leading: widget.overrideLeading ?? const Icon(Icons.search),
        trailing: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: controller.clear,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _qrCode,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: _tryClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward).animate(
              onInit: (controller) => arrowSpinningController = controller,
              effects: const [RotateEffect()],
              autoPlay: false,
            ),
            onPressed: _launch,
          ),
        ],
      ),
    );
  }
}
