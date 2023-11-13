// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class AndroidGallery implements GalleryPlug {
  @override
  GalleryAPIDirectories galleryApi() =>
      _AndroidGallery(BackgroundCellLoader.directories());

  const AndroidGallery();
}

Future<void> initalizeAndroidGallery(bool temporary) async {
  await BackgroundCellLoader.cacheDirectories();
  await BackgroundCellLoader.cacheFiles();

  {
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        "lol.bruh19.azari.gallery.api.updateDirectories", (message) async {
      BackgroundCellLoader.directories().send(
          Binary(message!, type: BackgroundCellLoader.directoryBinaryType));

      return const StandardMessageCodec().encodeMessage(<Object?>[]);
    });
  }
  {
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        "lol.bruh19.azari.gallery.api.updateFiles", (message) {
      if (message!.getUint8(0) == 0) {
        BackgroundCellLoader.filesPrimary()
            .send(Binary(message, type: BackgroundCellLoader.filesBinaryType));
      } else {
        BackgroundCellLoader.filesSecondary()
            .send(Binary(message, type: BackgroundCellLoader.filesBinaryType));
      }

      return Future.value(
          const StandardMessageCodec().encodeMessage(<Object?>[]));
    });
  }
  {
    ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        "lol.bruh19.azari.gallery.api.notify", (message) async {
      BackgroundCellLoader.directories().send(const Poll());

      if (message!.getUint8(0) == 0) {
        BackgroundCellLoader.filesPrimary().state.reset();
      } else if (message.getUint8(0) == 1) {
        BackgroundCellLoader.filesSecondary().state.reset();
      }

      return const StandardMessageCodec().encodeMessage(<Object?>[]);
    });
  }
}
