import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'signal_db.g.dart';

/// Ratchet/session state. The identity PRIVATE key never lives here — it stays
/// in the Keychain (KeyVault). Keeping this in a DB (rather than scattered
/// Keychain entries) is what makes an encrypted backup feasible later.
class SignalSessions extends Table {
  TextColumn get name => text()();
  IntColumn get deviceNum => integer()();
  BlobColumn get record => blob()();

  @override
  Set<Column> get primaryKey => {name, deviceNum};
}

class SignalPrekeys extends Table {
  IntColumn get prekeyId => integer()();
  BlobColumn get record => blob()();

  @override
  Set<Column> get primaryKey => {prekeyId};
}

class SignalSignedPrekeys extends Table {
  IntColumn get signedPrekeyId => integer()();
  BlobColumn get record => blob()();

  @override
  Set<Column> get primaryKey => {signedPrekeyId};
}

class SignalIdentities extends Table {
  TextColumn get name => text()();
  IntColumn get deviceNum => integer()();
  BlobColumn get identityKey => blob()();
  DateTimeColumn get firstSeen => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {name, deviceNum};
}

/// Recorded when a known address presents a different identity key, so chat can
/// surface "their security code changed".
class SignalIdentityChanges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get deviceNum => integer()();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  SignalSessions,
  SignalPrekeys,
  SignalSignedPrekeys,
  SignalIdentities,
  SignalIdentityChanges,
])
class SignalDb extends _$SignalDb {
  SignalDb() : super(driftDatabase(name: 'sakinah_signal'));

  /// In-memory instance for tests.
  SignalDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
