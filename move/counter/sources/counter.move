// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This example demonstrates a basic use of a shared object.
/// Rules:
/// - anyone can create and share a counter
/// - everyone can increment a counter by 1
/// - the owner of the counter can reset it to any value
module counter::counter {
  use sui::event;
  use sui::transfer;
  use sui::tx_context::{TxContext, sender};
  use sui::object::{Self, UID, ID};

  const E_UNDERFLOW: u64 = 1;
  const E_NOT_OWNER: u64 = 2;

  /// A shared counter.
  public struct Counter has key {
    id: UID,
    owner: address,
    value: u64
  }

  public struct OwnerCap has key {
    id: UID,
  }

  /// Create and share a Counter object.
  public fun create(ctx: &mut TxContext) {
    transfer::share_object(Counter {
      id: object::new(ctx),
      owner: tx_context::sender(ctx),
      value: 0
    })
  }

  /// Increment a counter by 1.
  public fun increment(counter: &mut Counter) {
    counter.value = counter.value + 1;
    emit_counter_event(counter, counter.value);
  }

  /// Decrement a counter by 1.
  public fun decrement(counter: &mut Counter) {
    assert!(counter.value > 0, E_UNDERFLOW);
    counter.value = counter.value - 1;
    emit_counter_event(counter, counter.value);
  }

  /// Define a custom event type for counter changes (stores object ID, not owner).
  public struct CounterEvent has copy, drop, store {
    counter_id: ID,
    new_value: u64,
  }

  /// Event to track counter changes without moving the UID.
  public fun emit_counter_event(counter: &Counter, new_value: u64) {
    event::emit<CounterEvent>(CounterEvent {
      counter_id: object::id(counter),
      new_value
    });
  }

  /// Set value (only runnable by the Counter owner)
  public fun set_value(counter: &mut Counter, value: u64, ctx: &TxContext) {
    assert!(counter.owner == sender(ctx), E_NOT_OWNER);
    counter.value = value;
    emit_counter_event(counter, counter.value);
  }
}
