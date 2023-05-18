import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/system_gestures.dart';
import 'package:isar/isar.dart';

class LostDownloads extends StatefulWidget {
  const LostDownloads({super.key});

  @override
  State<LostDownloads> createState() => _LostDownloadsState();
}

class _LostDownloadsState extends State<LostDownloads> {
  List<File>? _files;
  late final StreamSubscription<void> _updates;
  final Downloader downloader = Downloader();

  @override
  void initState() {
    super.initState();

    downloader.markStale();

    _updates = isar().files.watchLazy(fireImmediately: true).listen((_) async {
      var filesInProgress = await isar()
          .files
          .filter()
          .inProgressEqualTo(true)
          .sortByDateDesc()
          .findAll();
      var files = await isar()
          .files
          .filter()
          .inProgressEqualTo(false)
          .sortByDateDesc()
          .findAll();
      filesInProgress.addAll(files);
      setState(() {
        _files = filesInProgress;
      });
    });
  }

  @override
  void dispose() {
    _updates.cancel();

    super.dispose();
  }

  int _inProcess() => isar().files.filter().isFailedEqualTo(false).countSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _files == null
              ? "Downloads"
              : _files!.isEmpty
                  ? "Downloads (empty)"
                  : "Downloads (${_inProcess().toString()}/${_files!.length.toString()})",
        ),
        actions: [
          IconButton(
              onPressed: () {
                downloader.markStale();
              },
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () {
                downloader.removeFailed();
              },
              icon: const Icon(Icons.close))
        ],
      ),
      body: gestureDeadZones(context,
          child: _files == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: _files!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onLongPress: () {
                        var file = _files![index];
                        Navigator.push(
                            context,
                            DialogRoute(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("no")),
                                      TextButton(
                                          onPressed: () {
                                            downloader.retry(file);
                                            Navigator.pop(context);
                                          },
                                          child: const Text("yes")),
                                    ],
                                    title:
                                        Text(downloader.downloadAction(file)),
                                    content: Text(file.name),
                                  );
                                }));
                      },
                      title: Text(
                          "${_files![index].site}: ${_files![index].name}"),
                      subtitle:
                          Text(downloader.downloadDescription(_files![index])),
                    );
                  },
                )),
    );
  }
}
