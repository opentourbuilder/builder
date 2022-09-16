import 'package:flutter/material.dart';

import './db.dart';
import 'models/waypoint.dart';

class FullWaypointId {
  const FullWaypointId({
    required this.tourId,
    required this.waypointId,
  });

  final Uuid tourId;
  final Uuid waypointId;

  @override
  int get hashCode => Object.hash(tourId, waypointId);

  @override
  operator ==(Object other) =>
      other is FullWaypointId &&
      other.tourId == tourId &&
      other.waypointId == waypointId;
}

abstract class DbObject<I, D> {
  DbObject(DbObjectInfo<I, D, DbObject<I, D>> info)
      : info = WeakReference(info);

  final WeakReference<DbObjectInfo<I, D, DbObject<I, D>>> info;

  void listen(VoidCallback callback) {
    info.target?.listen(this, callback);
  }

  void cancel() {
    info.target?.cancel(this);
  }

  @protected
  void notify() {
    info.target?.notify(this);
  }
}

abstract class DbObjectInfo<I, D, O extends DbObject<I, D>> {
  DbObjectInfo({
    required this.id,
    required this.data,
  });

  final I id;
  final D data;
  final Map<O, VoidCallback> listeners = {};

  bool deleted = false;

  void listen(O key, VoidCallback callback) {
    if (deleted) return;

    listeners[key] = callback;
  }

  void cancel(O key) {
    if (deleted) return;

    listeners.remove(key);

    if (listeners.isEmpty) {
      instance.dbObjects[id] = null;
    }
  }

  void notify(O sender) {
    for (var listener in listeners.entries) {
      if (!identical(sender, listener.key)) {
        listener.value();
      }
    }
  }

  Future<void> persist();
}
