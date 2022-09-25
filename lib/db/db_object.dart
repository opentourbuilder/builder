import 'package:flutter/material.dart';

import './db.dart';

abstract class DbObject<DataAccessor, Id, Data> {
  DbObject(DataAccessor Function(DbObject<DataAccessor, Id, Data>) data,
      DbObjectState<Id, Data> state)
      : _state = state {
    _data = data(this);
    state.register(this, (deleted) {
      if (deleted) _data = _state = null;

      _changed = true;
    });
  }

  late DataAccessor? _data;
  DbObjectState<Id, Data>? _state;
  bool _changed = false;

  /// Returns true if the object has been changed by some other accessor of the
  /// object since this property was last accessed.
  bool get changed {
    if (_changed) {
      _changed = false;
      return true;
    } else {
      return false;
    }
  }

  /// The data associated with this database object.
  ///
  /// Null if the object has been deleted from the database.
  DataAccessor? get data => _data;

  /// The state associated with this database object.
  ///
  /// Null if the object has been deleted from the database
  DbObjectState<Id, Data>? get state => _state;

  /// Sets the callback that gets run whenever the object is updated.
  void listen(VoidCallback onUpdate) {
    _state?.register(this, (deleted) {
      if (deleted) _data = _state = null;

      _changed = true;
      onUpdate();
    });
  }

  /// Mark this object as unused so that resources can be freed if necessary.
  ///
  /// This should always be called to dispose of an object after it is no longer
  /// needed.
  void dispose() {
    _state?.dispose(this);
  }
}

class DbObjectState<Id, Data> {
  DbObjectState(this.id, this.data);

  final Id id;
  final Data data;
  final Map<Object, void Function(bool deleted)> _instances = {};

  bool _deleted = false;

  void markDeleted() {
    _deleted = true;
  }

  // Registers state related to the DbObject with the given key.
  void register(Object key, void Function(bool deleted) callback) {
    if (_deleted) return;

    _instances[key] = callback;
  }

  /// Disposes of state related to the DbObject with the given key.
  void dispose(Object key) {
    if (_deleted) return;

    _instances.remove(key);

    if (_instances.isEmpty) {
      instance.dbObjects.remove(id);
    }
  }

  /// Notifies all listeners other than `sender` that the object has been
  /// modified.
  void notify(Object? sender) {
    for (var listener in _instances.entries) {
      if (!identical(sender, listener.key)) {
        listener.value(_deleted);
      }
    }
  }
}
