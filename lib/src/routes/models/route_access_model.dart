import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

@immutable
final class RouteAccessModel {
  final String path;
  final String? branch;

  const RouteAccessModel(this.path, [this.branch]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteAccessModel &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          branch == other.branch;

  @override
  int get hashCode => Object.hash(path, branch);

  @override
  String toString() => 'RouteAccessModel($path, $branch)';
}
