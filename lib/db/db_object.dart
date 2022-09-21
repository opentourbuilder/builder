import 'package:flutter/material.dart';

import './db.dart';

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

abstract class DbObject<Id, D, Info extends DbObjectInfo<Id, D, Info>> {
  DbObject(Info info) : _infoRef = WeakReference(info);

  final WeakReference<Info> _infoRef;

  Info? get info => _infoRef.target;

  void listen(VoidCallback callback) {
    info?.listen(this, callback);
  }

  void cancel() {
    info?.cancel(this);
  }

  @protected
  void notify() {
    info?.notify(this);
  }
}

abstract class DbObjectInfo<Id, D, Self extends DbObjectInfo<Id, D, Self>> {
  DbObjectInfo({
    required this.id,
    required this.data,
  });

  final Id id;
  final D data;
  final Map<Object, VoidCallback> listeners = {};

  bool deleted = false;

  void listen(Object key, VoidCallback callback) {
    if (deleted) return;

    listeners[key] = callback;
  }

  void cancel(Object key) {
    if (deleted) return;

    listeners.remove(key);

    if (listeners.isEmpty) {
      instance.dbObjects.remove(id);
    }
  }

  void notify(Object sender) {
    for (var listener in listeners.entries) {
      if (!identical(sender, listener.key)) {
        listener.value();
      }
    }
  }
}
