import 'package:flutter/foundation.dart';

class PeerChangeNotifierParent<
    Deleg extends PeerChangeNotifierDelegate<Data, Deleg>, Data> {
  PeerChangeNotifierParent(this.data, this.createDelegate);

  final Data data;
  final Deleg Function(Data) createDelegate;
  final List<PeerChangeNotifier<Deleg, Data>> peers = [];

  PeerChangeNotifier<Deleg, Data> newPeer() => PeerChangeNotifier._(this);

  void _notifyPeers(PeerChangeNotifier<Deleg, Data> notifyingPeer) {
    for (var peer in peers) {
      if (peer != notifyingPeer) {
        peer.onChanged();
      }
    }
  }

  void _disposePeer(PeerChangeNotifier<Deleg, Data> peer) {
    peers.remove(peer);
  }
}

class PeerChangeNotifier<Deleg extends PeerChangeNotifierDelegate<Data, Deleg>,
    Data> {
  PeerChangeNotifier._(this.parent) : data = parent.createDelegate(parent.data);

  final PeerChangeNotifierParent<Deleg, Data> parent;
  final Deleg data;

  void Function() onChanged = () {};

  void dispose() {
    parent._disposePeer(this);
  }
}

class PeerChangeNotifierDelegate<Data,
    Self extends PeerChangeNotifierDelegate<Data, Self>> {
  const PeerChangeNotifierDelegate(this._peer);

  final PeerChangeNotifier<Self, Data> _peer;

  @protected
  void notifyPeers() {
    _peer.parent._notifyPeers(_peer);
  }
}
