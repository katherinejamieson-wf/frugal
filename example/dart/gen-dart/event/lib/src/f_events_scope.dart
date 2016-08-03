// Autogenerated by Frugal Compiler (1.12.1)
// DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING

library event.src.f_events_scope;

import 'dart:async';

import 'package:thrift/thrift.dart' as thrift;
import 'package:frugal/frugal.dart' as frugal;

import 'package:event/event.dart' as t_event;


const String delimiter = '.';

/// This docstring gets added to the generated code because it has
/// the @ sign. Prefix specifies topic prefix tokens, which can be static or
/// variable.
class EventsPublisher {
  frugal.FScopeTransport fTransport;
  frugal.FProtocol fProtocol;
  Map<String, frugal.FMethod> _methods;
  frugal.Lock _writeLock;

  EventsPublisher(frugal.FScopeProvider provider, [List<frugal.Middleware> middleware]) {
    fTransport = provider.fTransportFactory.getTransport();
    fProtocol = provider.fProtocolFactory.getProtocol(fTransport);
    _writeLock = new frugal.Lock();
    this._methods = {};
    this._methods['EventCreated'] = new frugal.FMethod(this._publishEventCreated, 'Events', 'publishEventCreated', middleware);
  }

  Future open() {
    return fTransport.open();
  }

  Future close() {
    return fTransport.close();
  }

  /// This is a docstring.
  Future publishEventCreated(frugal.FContext ctx, String user, t_event.Event req) {
    return this._methods['EventCreated']([ctx, user, req]);
  }

  Future _publishEventCreated(frugal.FContext ctx, String user, t_event.Event req) async {
    _writeLock.lock();
    var op = "EventCreated";
    var prefix = "foo.${user}.";
    var topic = "${prefix}Events${delimiter}${op}";
    fTransport.setTopic(topic);
    var oprot = fProtocol;
    var msg = new thrift.TMessage(op, thrift.TMessageType.CALL, 0);
    oprot.writeRequestHeader(ctx);
    oprot.writeMessageBegin(msg);
    req.write(oprot);
    oprot.writeMessageEnd();
    await oprot.transport.flush();
    _writeLock.unlock();
  }
}


/// This docstring gets added to the generated code because it has
/// the @ sign. Prefix specifies topic prefix tokens, which can be static or
/// variable.
class EventsSubscriber {
  final frugal.FScopeProvider provider;
  final List<frugal.Middleware> _middleware;

  EventsSubscriber(this.provider, [this._middleware]) {}

  /// This is a docstring.
  Future<frugal.FSubscription> subscribeEventCreated(String user, dynamic onEvent(frugal.FContext ctx, t_event.Event req)) async {
    var op = "EventCreated";
    var prefix = "foo.${user}.";
    var topic = "${prefix}Events${delimiter}${op}";
    var transport = provider.fTransportFactory.getTransport();
    await transport.subscribe(topic, _recvEventCreated(op, provider.fProtocolFactory, onEvent));
    return new frugal.FSubscription(topic, transport);
  }

  _recvEventCreated(String op, frugal.FProtocolFactory protocolFactory, dynamic onEvent(frugal.FContext ctx, t_event.Event req)) {
    frugal.FMethod method = new frugal.FMethod(onEvent, 'Events', 'subscribeEvent', this._middleware);
    callbackEventCreated(thrift.TTransport transport) {
      var iprot = protocolFactory.getProtocol(transport);
      var ctx = iprot.readRequestHeader();
      var tMsg = iprot.readMessageBegin();
      if (tMsg.name != op) {
        thrift.TProtocolUtil.skip(iprot, thrift.TType.STRUCT);
        iprot.readMessageEnd();
        throw new thrift.TApplicationError(
        thrift.TApplicationErrorType.UNKNOWN_METHOD, tMsg.name);
      }
      var req = new t_event.Event();
      req.read(iprot);
      iprot.readMessageEnd();
      method([ctx, req]);
    }
    return callbackEventCreated;
  }
}

