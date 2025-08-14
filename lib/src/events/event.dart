// coverage:ignore-file

import 'dart:async';

import 'package:event_bus/event_bus.dart';

/// Global default EventBus for the modular system.
///
/// This bus is used whenever a custom EventBus is not provided,
/// enabling decoupled communication between modules and components.
final EventBus defaultEvents = EventBus();

/// Tracks all active event subscriptions per EventBus and event type.
///
/// The structure is:
/// ```dart
/// Map<EventBusId, Map<EventType, StreamSubscription>>
/// ```
/// - `EventBusId`: Unique identifier for the EventBus instance (hashCode).
/// - `EventType`: Type of the event being listened to (`Type.runtimeType`).
/// - `StreamSubscription`: Active subscription for that event type.
///
/// This map allows modules and components to:
/// - Track which listeners are currently active.
/// - Dispose individual subscriptions or all subscriptions per EventBus.
/// - Prevent memory leaks by ensuring proper cleanup.
final Map<int, Map<Type, StreamSubscription<dynamic>>> eventSubscriptions = {};
