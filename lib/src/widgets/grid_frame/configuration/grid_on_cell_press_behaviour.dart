// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import 'package:flutter/material.dart';
// import 'package:gallery/src/interfaces/cell/cell.dart';
// import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
// import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
// import 'package:gallery/src/widgets/image_view/image_view.dart';

// abstract class GridOnCellPressedBehaviour {
//   const GridOnCellPressedBehaviour();

//   Future<void> launch<T extends CellBase>(
//     BuildContext gridContext,
//     int startingCell,
//     GridFunctionality<T> state, {
//     double? startingOffset,
//     T? useCellInsteadIdx,
//   });
// }

// class OverrideGridOnCellPressBehaviour implements GridOnCellPressedBehaviour {
//   const OverrideGridOnCellPressBehaviour({
//     this.onPressed = _doNothing,
//   });

//   static Future<void> _doNothing(
//     BuildContext context,
//     int idx,
//     CellBase? overrideCell,
//   ) {
//     return Future.value();
//   }

//   final Future<void> Function(
//     BuildContext context,
//     int idx,
//     CellBase? overrideCell,
//   ) onPressed;

//   @override
//   Future<void> launch<T extends CellBase>(
//     BuildContext gridContext,
//     int startingCell,
//     GridFunctionality<T> functionality, {
//     double? startingOffset,
//     T? useCellInsteadIdx,
//   }) {
//     return onPressed(gridContext, startingCell, useCellInsteadIdx);
//   }
// }

// class DefaultGridOnCellPressBehaviour implements GridOnCellPressedBehaviour {
//   const DefaultGridOnCellPressBehaviour();

//   @override
//   Future<void> launch<T extends CellBase>(
//     BuildContext gridContext,
//     int startingCell,
//     GridFunctionality<T> functionality, {
//     double? startingOffset,
//     T? useCellInsteadIdx,
//   }) {
//   }
// }
