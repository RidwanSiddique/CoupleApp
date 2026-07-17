// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_db.dart';

// ignore_for_file: type=lint
class $SignalSessionsTable extends SignalSessions
    with TableInfo<$SignalSessionsTable, SignalSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNumMeta = const VerificationMeta(
    'deviceNum',
  );
  @override
  late final GeneratedColumn<int> deviceNum = GeneratedColumn<int>(
    'device_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  @override
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
    'record',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, deviceNum, record];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_num')) {
      context.handle(
        _deviceNumMeta,
        deviceNum.isAcceptableOrUnknown(data['device_num']!, _deviceNumMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNumMeta);
    }
    if (data.containsKey('record')) {
      context.handle(
        _recordMeta,
        record.isAcceptableOrUnknown(data['record']!, _recordMeta),
      );
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name, deviceNum};
  @override
  SignalSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSession(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deviceNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_num'],
      )!,
      record: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}record'],
      )!,
    );
  }

  @override
  $SignalSessionsTable createAlias(String alias) {
    return $SignalSessionsTable(attachedDatabase, alias);
  }
}

class SignalSession extends DataClass implements Insertable<SignalSession> {
  final String name;
  final int deviceNum;
  final Uint8List record;
  const SignalSession({
    required this.name,
    required this.deviceNum,
    required this.record,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['device_num'] = Variable<int>(deviceNum);
    map['record'] = Variable<Uint8List>(record);
    return map;
  }

  SignalSessionsCompanion toCompanion(bool nullToAbsent) {
    return SignalSessionsCompanion(
      name: Value(name),
      deviceNum: Value(deviceNum),
      record: Value(record),
    );
  }

  factory SignalSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSession(
      name: serializer.fromJson<String>(json['name']),
      deviceNum: serializer.fromJson<int>(json['deviceNum']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'deviceNum': serializer.toJson<int>(deviceNum),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  SignalSession copyWith({String? name, int? deviceNum, Uint8List? record}) =>
      SignalSession(
        name: name ?? this.name,
        deviceNum: deviceNum ?? this.deviceNum,
        record: record ?? this.record,
      );
  SignalSession copyWithCompanion(SignalSessionsCompanion data) {
    return SignalSession(
      name: data.name.present ? data.name.value : this.name,
      deviceNum: data.deviceNum.present ? data.deviceNum.value : this.deviceNum,
      record: data.record.present ? data.record.value : this.record,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSession(')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, deviceNum, $driftBlobEquality.hash(record));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSession &&
          other.name == this.name &&
          other.deviceNum == this.deviceNum &&
          $driftBlobEquality.equals(other.record, this.record));
}

class SignalSessionsCompanion extends UpdateCompanion<SignalSession> {
  final Value<String> name;
  final Value<int> deviceNum;
  final Value<Uint8List> record;
  final Value<int> rowid;
  const SignalSessionsCompanion({
    this.name = const Value.absent(),
    this.deviceNum = const Value.absent(),
    this.record = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSessionsCompanion.insert({
    required String name,
    required int deviceNum,
    required Uint8List record,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       deviceNum = Value(deviceNum),
       record = Value(record);
  static Insertable<SignalSession> custom({
    Expression<String>? name,
    Expression<int>? deviceNum,
    Expression<Uint8List>? record,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (deviceNum != null) 'device_num': deviceNum,
      if (record != null) 'record': record,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalSessionsCompanion copyWith({
    Value<String>? name,
    Value<int>? deviceNum,
    Value<Uint8List>? record,
    Value<int>? rowid,
  }) {
    return SignalSessionsCompanion(
      name: name ?? this.name,
      deviceNum: deviceNum ?? this.deviceNum,
      record: record ?? this.record,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceNum.present) {
      map['device_num'] = Variable<int>(deviceNum.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSessionsCompanion(')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('record: $record, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalPrekeysTable extends SignalPrekeys
    with TableInfo<$SignalPrekeysTable, SignalPrekey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalPrekeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prekeyIdMeta = const VerificationMeta(
    'prekeyId',
  );
  @override
  late final GeneratedColumn<int> prekeyId = GeneratedColumn<int>(
    'prekey_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  @override
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
    'record',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [prekeyId, record];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_prekeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalPrekey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prekey_id')) {
      context.handle(
        _prekeyIdMeta,
        prekeyId.isAcceptableOrUnknown(data['prekey_id']!, _prekeyIdMeta),
      );
    }
    if (data.containsKey('record')) {
      context.handle(
        _recordMeta,
        record.isAcceptableOrUnknown(data['record']!, _recordMeta),
      );
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prekeyId};
  @override
  SignalPrekey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalPrekey(
      prekeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prekey_id'],
      )!,
      record: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}record'],
      )!,
    );
  }

  @override
  $SignalPrekeysTable createAlias(String alias) {
    return $SignalPrekeysTable(attachedDatabase, alias);
  }
}

class SignalPrekey extends DataClass implements Insertable<SignalPrekey> {
  final int prekeyId;
  final Uint8List record;
  const SignalPrekey({required this.prekeyId, required this.record});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prekey_id'] = Variable<int>(prekeyId);
    map['record'] = Variable<Uint8List>(record);
    return map;
  }

  SignalPrekeysCompanion toCompanion(bool nullToAbsent) {
    return SignalPrekeysCompanion(
      prekeyId: Value(prekeyId),
      record: Value(record),
    );
  }

  factory SignalPrekey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalPrekey(
      prekeyId: serializer.fromJson<int>(json['prekeyId']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prekeyId': serializer.toJson<int>(prekeyId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  SignalPrekey copyWith({int? prekeyId, Uint8List? record}) => SignalPrekey(
    prekeyId: prekeyId ?? this.prekeyId,
    record: record ?? this.record,
  );
  SignalPrekey copyWithCompanion(SignalPrekeysCompanion data) {
    return SignalPrekey(
      prekeyId: data.prekeyId.present ? data.prekeyId.value : this.prekeyId,
      record: data.record.present ? data.record.value : this.record,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalPrekey(')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prekeyId, $driftBlobEquality.hash(record));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalPrekey &&
          other.prekeyId == this.prekeyId &&
          $driftBlobEquality.equals(other.record, this.record));
}

class SignalPrekeysCompanion extends UpdateCompanion<SignalPrekey> {
  final Value<int> prekeyId;
  final Value<Uint8List> record;
  const SignalPrekeysCompanion({
    this.prekeyId = const Value.absent(),
    this.record = const Value.absent(),
  });
  SignalPrekeysCompanion.insert({
    this.prekeyId = const Value.absent(),
    required Uint8List record,
  }) : record = Value(record);
  static Insertable<SignalPrekey> custom({
    Expression<int>? prekeyId,
    Expression<Uint8List>? record,
  }) {
    return RawValuesInsertable({
      if (prekeyId != null) 'prekey_id': prekeyId,
      if (record != null) 'record': record,
    });
  }

  SignalPrekeysCompanion copyWith({
    Value<int>? prekeyId,
    Value<Uint8List>? record,
  }) {
    return SignalPrekeysCompanion(
      prekeyId: prekeyId ?? this.prekeyId,
      record: record ?? this.record,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prekeyId.present) {
      map['prekey_id'] = Variable<int>(prekeyId.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalPrekeysCompanion(')
          ..write('prekeyId: $prekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }
}

class $SignalSignedPrekeysTable extends SignalSignedPrekeys
    with TableInfo<$SignalSignedPrekeysTable, SignalSignedPrekey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSignedPrekeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _signedPrekeyIdMeta = const VerificationMeta(
    'signedPrekeyId',
  );
  @override
  late final GeneratedColumn<int> signedPrekeyId = GeneratedColumn<int>(
    'signed_prekey_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordMeta = const VerificationMeta('record');
  @override
  late final GeneratedColumn<Uint8List> record = GeneratedColumn<Uint8List>(
    'record',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [signedPrekeyId, record];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_signed_prekeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSignedPrekey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('signed_prekey_id')) {
      context.handle(
        _signedPrekeyIdMeta,
        signedPrekeyId.isAcceptableOrUnknown(
          data['signed_prekey_id']!,
          _signedPrekeyIdMeta,
        ),
      );
    }
    if (data.containsKey('record')) {
      context.handle(
        _recordMeta,
        record.isAcceptableOrUnknown(data['record']!, _recordMeta),
      );
    } else if (isInserting) {
      context.missing(_recordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {signedPrekeyId};
  @override
  SignalSignedPrekey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSignedPrekey(
      signedPrekeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}signed_prekey_id'],
      )!,
      record: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}record'],
      )!,
    );
  }

  @override
  $SignalSignedPrekeysTable createAlias(String alias) {
    return $SignalSignedPrekeysTable(attachedDatabase, alias);
  }
}

class SignalSignedPrekey extends DataClass
    implements Insertable<SignalSignedPrekey> {
  final int signedPrekeyId;
  final Uint8List record;
  const SignalSignedPrekey({
    required this.signedPrekeyId,
    required this.record,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['signed_prekey_id'] = Variable<int>(signedPrekeyId);
    map['record'] = Variable<Uint8List>(record);
    return map;
  }

  SignalSignedPrekeysCompanion toCompanion(bool nullToAbsent) {
    return SignalSignedPrekeysCompanion(
      signedPrekeyId: Value(signedPrekeyId),
      record: Value(record),
    );
  }

  factory SignalSignedPrekey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSignedPrekey(
      signedPrekeyId: serializer.fromJson<int>(json['signedPrekeyId']),
      record: serializer.fromJson<Uint8List>(json['record']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'signedPrekeyId': serializer.toJson<int>(signedPrekeyId),
      'record': serializer.toJson<Uint8List>(record),
    };
  }

  SignalSignedPrekey copyWith({int? signedPrekeyId, Uint8List? record}) =>
      SignalSignedPrekey(
        signedPrekeyId: signedPrekeyId ?? this.signedPrekeyId,
        record: record ?? this.record,
      );
  SignalSignedPrekey copyWithCompanion(SignalSignedPrekeysCompanion data) {
    return SignalSignedPrekey(
      signedPrekeyId: data.signedPrekeyId.present
          ? data.signedPrekeyId.value
          : this.signedPrekeyId,
      record: data.record.present ? data.record.value : this.record,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSignedPrekey(')
          ..write('signedPrekeyId: $signedPrekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(signedPrekeyId, $driftBlobEquality.hash(record));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSignedPrekey &&
          other.signedPrekeyId == this.signedPrekeyId &&
          $driftBlobEquality.equals(other.record, this.record));
}

class SignalSignedPrekeysCompanion extends UpdateCompanion<SignalSignedPrekey> {
  final Value<int> signedPrekeyId;
  final Value<Uint8List> record;
  const SignalSignedPrekeysCompanion({
    this.signedPrekeyId = const Value.absent(),
    this.record = const Value.absent(),
  });
  SignalSignedPrekeysCompanion.insert({
    this.signedPrekeyId = const Value.absent(),
    required Uint8List record,
  }) : record = Value(record);
  static Insertable<SignalSignedPrekey> custom({
    Expression<int>? signedPrekeyId,
    Expression<Uint8List>? record,
  }) {
    return RawValuesInsertable({
      if (signedPrekeyId != null) 'signed_prekey_id': signedPrekeyId,
      if (record != null) 'record': record,
    });
  }

  SignalSignedPrekeysCompanion copyWith({
    Value<int>? signedPrekeyId,
    Value<Uint8List>? record,
  }) {
    return SignalSignedPrekeysCompanion(
      signedPrekeyId: signedPrekeyId ?? this.signedPrekeyId,
      record: record ?? this.record,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (signedPrekeyId.present) {
      map['signed_prekey_id'] = Variable<int>(signedPrekeyId.value);
    }
    if (record.present) {
      map['record'] = Variable<Uint8List>(record.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSignedPrekeysCompanion(')
          ..write('signedPrekeyId: $signedPrekeyId, ')
          ..write('record: $record')
          ..write(')'))
        .toString();
  }
}

class $SignalIdentitiesTable extends SignalIdentities
    with TableInfo<$SignalIdentitiesTable, SignalIdentity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalIdentitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNumMeta = const VerificationMeta(
    'deviceNum',
  );
  @override
  late final GeneratedColumn<int> deviceNum = GeneratedColumn<int>(
    'device_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityKeyMeta = const VerificationMeta(
    'identityKey',
  );
  @override
  late final GeneratedColumn<Uint8List> identityKey =
      GeneratedColumn<Uint8List>(
        'identity_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    deviceNum,
    identityKey,
    firstSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_identities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalIdentity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_num')) {
      context.handle(
        _deviceNumMeta,
        deviceNum.isAcceptableOrUnknown(data['device_num']!, _deviceNumMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNumMeta);
    }
    if (data.containsKey('identity_key')) {
      context.handle(
        _identityKeyMeta,
        identityKey.isAcceptableOrUnknown(
          data['identity_key']!,
          _identityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name, deviceNum};
  @override
  SignalIdentity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalIdentity(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deviceNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_num'],
      )!,
      identityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}identity_key'],
      )!,
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen'],
      )!,
    );
  }

  @override
  $SignalIdentitiesTable createAlias(String alias) {
    return $SignalIdentitiesTable(attachedDatabase, alias);
  }
}

class SignalIdentity extends DataClass implements Insertable<SignalIdentity> {
  final String name;
  final int deviceNum;
  final Uint8List identityKey;
  final DateTime firstSeen;
  const SignalIdentity({
    required this.name,
    required this.deviceNum,
    required this.identityKey,
    required this.firstSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['device_num'] = Variable<int>(deviceNum);
    map['identity_key'] = Variable<Uint8List>(identityKey);
    map['first_seen'] = Variable<DateTime>(firstSeen);
    return map;
  }

  SignalIdentitiesCompanion toCompanion(bool nullToAbsent) {
    return SignalIdentitiesCompanion(
      name: Value(name),
      deviceNum: Value(deviceNum),
      identityKey: Value(identityKey),
      firstSeen: Value(firstSeen),
    );
  }

  factory SignalIdentity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalIdentity(
      name: serializer.fromJson<String>(json['name']),
      deviceNum: serializer.fromJson<int>(json['deviceNum']),
      identityKey: serializer.fromJson<Uint8List>(json['identityKey']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'deviceNum': serializer.toJson<int>(deviceNum),
      'identityKey': serializer.toJson<Uint8List>(identityKey),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
    };
  }

  SignalIdentity copyWith({
    String? name,
    int? deviceNum,
    Uint8List? identityKey,
    DateTime? firstSeen,
  }) => SignalIdentity(
    name: name ?? this.name,
    deviceNum: deviceNum ?? this.deviceNum,
    identityKey: identityKey ?? this.identityKey,
    firstSeen: firstSeen ?? this.firstSeen,
  );
  SignalIdentity copyWithCompanion(SignalIdentitiesCompanion data) {
    return SignalIdentity(
      name: data.name.present ? data.name.value : this.name,
      deviceNum: data.deviceNum.present ? data.deviceNum.value : this.deviceNum,
      identityKey: data.identityKey.present
          ? data.identityKey.value
          : this.identityKey,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentity(')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('identityKey: $identityKey, ')
          ..write('firstSeen: $firstSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    name,
    deviceNum,
    $driftBlobEquality.hash(identityKey),
    firstSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalIdentity &&
          other.name == this.name &&
          other.deviceNum == this.deviceNum &&
          $driftBlobEquality.equals(other.identityKey, this.identityKey) &&
          other.firstSeen == this.firstSeen);
}

class SignalIdentitiesCompanion extends UpdateCompanion<SignalIdentity> {
  final Value<String> name;
  final Value<int> deviceNum;
  final Value<Uint8List> identityKey;
  final Value<DateTime> firstSeen;
  final Value<int> rowid;
  const SignalIdentitiesCompanion({
    this.name = const Value.absent(),
    this.deviceNum = const Value.absent(),
    this.identityKey = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalIdentitiesCompanion.insert({
    required String name,
    required int deviceNum,
    required Uint8List identityKey,
    this.firstSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       deviceNum = Value(deviceNum),
       identityKey = Value(identityKey);
  static Insertable<SignalIdentity> custom({
    Expression<String>? name,
    Expression<int>? deviceNum,
    Expression<Uint8List>? identityKey,
    Expression<DateTime>? firstSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (deviceNum != null) 'device_num': deviceNum,
      if (identityKey != null) 'identity_key': identityKey,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalIdentitiesCompanion copyWith({
    Value<String>? name,
    Value<int>? deviceNum,
    Value<Uint8List>? identityKey,
    Value<DateTime>? firstSeen,
    Value<int>? rowid,
  }) {
    return SignalIdentitiesCompanion(
      name: name ?? this.name,
      deviceNum: deviceNum ?? this.deviceNum,
      identityKey: identityKey ?? this.identityKey,
      firstSeen: firstSeen ?? this.firstSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceNum.present) {
      map['device_num'] = Variable<int>(deviceNum.value);
    }
    if (identityKey.present) {
      map['identity_key'] = Variable<Uint8List>(identityKey.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentitiesCompanion(')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('identityKey: $identityKey, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalIdentityChangesTable extends SignalIdentityChanges
    with TableInfo<$SignalIdentityChangesTable, SignalIdentityChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalIdentityChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNumMeta = const VerificationMeta(
    'deviceNum',
  );
  @override
  late final GeneratedColumn<int> deviceNum = GeneratedColumn<int>(
    'device_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, deviceNum, changedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_identity_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalIdentityChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_num')) {
      context.handle(
        _deviceNumMeta,
        deviceNum.isAcceptableOrUnknown(data['device_num']!, _deviceNumMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNumMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignalIdentityChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalIdentityChange(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deviceNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_num'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $SignalIdentityChangesTable createAlias(String alias) {
    return $SignalIdentityChangesTable(attachedDatabase, alias);
  }
}

class SignalIdentityChange extends DataClass
    implements Insertable<SignalIdentityChange> {
  final int id;
  final String name;
  final int deviceNum;
  final DateTime changedAt;
  const SignalIdentityChange({
    required this.id,
    required this.name,
    required this.deviceNum,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['device_num'] = Variable<int>(deviceNum);
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  SignalIdentityChangesCompanion toCompanion(bool nullToAbsent) {
    return SignalIdentityChangesCompanion(
      id: Value(id),
      name: Value(name),
      deviceNum: Value(deviceNum),
      changedAt: Value(changedAt),
    );
  }

  factory SignalIdentityChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalIdentityChange(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deviceNum: serializer.fromJson<int>(json['deviceNum']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'deviceNum': serializer.toJson<int>(deviceNum),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  SignalIdentityChange copyWith({
    int? id,
    String? name,
    int? deviceNum,
    DateTime? changedAt,
  }) => SignalIdentityChange(
    id: id ?? this.id,
    name: name ?? this.name,
    deviceNum: deviceNum ?? this.deviceNum,
    changedAt: changedAt ?? this.changedAt,
  );
  SignalIdentityChange copyWithCompanion(SignalIdentityChangesCompanion data) {
    return SignalIdentityChange(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deviceNum: data.deviceNum.present ? data.deviceNum.value : this.deviceNum,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentityChange(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, deviceNum, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalIdentityChange &&
          other.id == this.id &&
          other.name == this.name &&
          other.deviceNum == this.deviceNum &&
          other.changedAt == this.changedAt);
}

class SignalIdentityChangesCompanion
    extends UpdateCompanion<SignalIdentityChange> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> deviceNum;
  final Value<DateTime> changedAt;
  const SignalIdentityChangesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceNum = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  SignalIdentityChangesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int deviceNum,
    this.changedAt = const Value.absent(),
  }) : name = Value(name),
       deviceNum = Value(deviceNum);
  static Insertable<SignalIdentityChange> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? deviceNum,
    Expression<DateTime>? changedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deviceNum != null) 'device_num': deviceNum,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  SignalIdentityChangesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? deviceNum,
    Value<DateTime>? changedAt,
  }) {
    return SignalIdentityChangesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceNum: deviceNum ?? this.deviceNum,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceNum.present) {
      map['device_num'] = Variable<int>(deviceNum.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentityChangesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceNum: $deviceNum, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SignalDb extends GeneratedDatabase {
  _$SignalDb(QueryExecutor e) : super(e);
  $SignalDbManager get managers => $SignalDbManager(this);
  late final $SignalSessionsTable signalSessions = $SignalSessionsTable(this);
  late final $SignalPrekeysTable signalPrekeys = $SignalPrekeysTable(this);
  late final $SignalSignedPrekeysTable signalSignedPrekeys =
      $SignalSignedPrekeysTable(this);
  late final $SignalIdentitiesTable signalIdentities = $SignalIdentitiesTable(
    this,
  );
  late final $SignalIdentityChangesTable signalIdentityChanges =
      $SignalIdentityChangesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signalSessions,
    signalPrekeys,
    signalSignedPrekeys,
    signalIdentities,
    signalIdentityChanges,
  ];
}

typedef $$SignalSessionsTableCreateCompanionBuilder =
    SignalSessionsCompanion Function({
      required String name,
      required int deviceNum,
      required Uint8List record,
      Value<int> rowid,
    });
typedef $$SignalSessionsTableUpdateCompanionBuilder =
    SignalSessionsCompanion Function({
      Value<String> name,
      Value<int> deviceNum,
      Value<Uint8List> record,
      Value<int> rowid,
    });

class $$SignalSessionsTableFilterComposer
    extends Composer<_$SignalDb, $SignalSessionsTable> {
  $$SignalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSessionsTableOrderingComposer
    extends Composer<_$SignalDb, $SignalSessionsTable> {
  $$SignalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSessionsTableAnnotationComposer
    extends Composer<_$SignalDb, $SignalSessionsTable> {
  $$SignalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get deviceNum =>
      $composableBuilder(column: $table.deviceNum, builder: (column) => column);

  GeneratedColumn<Uint8List> get record =>
      $composableBuilder(column: $table.record, builder: (column) => column);
}

class $$SignalSessionsTableTableManager
    extends
        RootTableManager<
          _$SignalDb,
          $SignalSessionsTable,
          SignalSession,
          $$SignalSessionsTableFilterComposer,
          $$SignalSessionsTableOrderingComposer,
          $$SignalSessionsTableAnnotationComposer,
          $$SignalSessionsTableCreateCompanionBuilder,
          $$SignalSessionsTableUpdateCompanionBuilder,
          (
            SignalSession,
            BaseReferences<_$SignalDb, $SignalSessionsTable, SignalSession>,
          ),
          SignalSession,
          PrefetchHooks Function()
        > {
  $$SignalSessionsTableTableManager(_$SignalDb db, $SignalSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> deviceNum = const Value.absent(),
                Value<Uint8List> record = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionsCompanion(
                name: name,
                deviceNum: deviceNum,
                record: record,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int deviceNum,
                required Uint8List record,
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionsCompanion.insert(
                name: name,
                deviceNum: deviceNum,
                record: record,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDb,
      $SignalSessionsTable,
      SignalSession,
      $$SignalSessionsTableFilterComposer,
      $$SignalSessionsTableOrderingComposer,
      $$SignalSessionsTableAnnotationComposer,
      $$SignalSessionsTableCreateCompanionBuilder,
      $$SignalSessionsTableUpdateCompanionBuilder,
      (
        SignalSession,
        BaseReferences<_$SignalDb, $SignalSessionsTable, SignalSession>,
      ),
      SignalSession,
      PrefetchHooks Function()
    >;
typedef $$SignalPrekeysTableCreateCompanionBuilder =
    SignalPrekeysCompanion Function({
      Value<int> prekeyId,
      required Uint8List record,
    });
typedef $$SignalPrekeysTableUpdateCompanionBuilder =
    SignalPrekeysCompanion Function({
      Value<int> prekeyId,
      Value<Uint8List> record,
    });

class $$SignalPrekeysTableFilterComposer
    extends Composer<_$SignalDb, $SignalPrekeysTable> {
  $$SignalPrekeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get prekeyId => $composableBuilder(
    column: $table.prekeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalPrekeysTableOrderingComposer
    extends Composer<_$SignalDb, $SignalPrekeysTable> {
  $$SignalPrekeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get prekeyId => $composableBuilder(
    column: $table.prekeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalPrekeysTableAnnotationComposer
    extends Composer<_$SignalDb, $SignalPrekeysTable> {
  $$SignalPrekeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get prekeyId =>
      $composableBuilder(column: $table.prekeyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get record =>
      $composableBuilder(column: $table.record, builder: (column) => column);
}

class $$SignalPrekeysTableTableManager
    extends
        RootTableManager<
          _$SignalDb,
          $SignalPrekeysTable,
          SignalPrekey,
          $$SignalPrekeysTableFilterComposer,
          $$SignalPrekeysTableOrderingComposer,
          $$SignalPrekeysTableAnnotationComposer,
          $$SignalPrekeysTableCreateCompanionBuilder,
          $$SignalPrekeysTableUpdateCompanionBuilder,
          (
            SignalPrekey,
            BaseReferences<_$SignalDb, $SignalPrekeysTable, SignalPrekey>,
          ),
          SignalPrekey,
          PrefetchHooks Function()
        > {
  $$SignalPrekeysTableTableManager(_$SignalDb db, $SignalPrekeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalPrekeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalPrekeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalPrekeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> prekeyId = const Value.absent(),
                Value<Uint8List> record = const Value.absent(),
              }) => SignalPrekeysCompanion(prekeyId: prekeyId, record: record),
          createCompanionCallback:
              ({
                Value<int> prekeyId = const Value.absent(),
                required Uint8List record,
              }) => SignalPrekeysCompanion.insert(
                prekeyId: prekeyId,
                record: record,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalPrekeysTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDb,
      $SignalPrekeysTable,
      SignalPrekey,
      $$SignalPrekeysTableFilterComposer,
      $$SignalPrekeysTableOrderingComposer,
      $$SignalPrekeysTableAnnotationComposer,
      $$SignalPrekeysTableCreateCompanionBuilder,
      $$SignalPrekeysTableUpdateCompanionBuilder,
      (
        SignalPrekey,
        BaseReferences<_$SignalDb, $SignalPrekeysTable, SignalPrekey>,
      ),
      SignalPrekey,
      PrefetchHooks Function()
    >;
typedef $$SignalSignedPrekeysTableCreateCompanionBuilder =
    SignalSignedPrekeysCompanion Function({
      Value<int> signedPrekeyId,
      required Uint8List record,
    });
typedef $$SignalSignedPrekeysTableUpdateCompanionBuilder =
    SignalSignedPrekeysCompanion Function({
      Value<int> signedPrekeyId,
      Value<Uint8List> record,
    });

class $$SignalSignedPrekeysTableFilterComposer
    extends Composer<_$SignalDb, $SignalSignedPrekeysTable> {
  $$SignalSignedPrekeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get signedPrekeyId => $composableBuilder(
    column: $table.signedPrekeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSignedPrekeysTableOrderingComposer
    extends Composer<_$SignalDb, $SignalSignedPrekeysTable> {
  $$SignalSignedPrekeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get signedPrekeyId => $composableBuilder(
    column: $table.signedPrekeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get record => $composableBuilder(
    column: $table.record,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSignedPrekeysTableAnnotationComposer
    extends Composer<_$SignalDb, $SignalSignedPrekeysTable> {
  $$SignalSignedPrekeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get signedPrekeyId => $composableBuilder(
    column: $table.signedPrekeyId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get record =>
      $composableBuilder(column: $table.record, builder: (column) => column);
}

class $$SignalSignedPrekeysTableTableManager
    extends
        RootTableManager<
          _$SignalDb,
          $SignalSignedPrekeysTable,
          SignalSignedPrekey,
          $$SignalSignedPrekeysTableFilterComposer,
          $$SignalSignedPrekeysTableOrderingComposer,
          $$SignalSignedPrekeysTableAnnotationComposer,
          $$SignalSignedPrekeysTableCreateCompanionBuilder,
          $$SignalSignedPrekeysTableUpdateCompanionBuilder,
          (
            SignalSignedPrekey,
            BaseReferences<
              _$SignalDb,
              $SignalSignedPrekeysTable,
              SignalSignedPrekey
            >,
          ),
          SignalSignedPrekey,
          PrefetchHooks Function()
        > {
  $$SignalSignedPrekeysTableTableManager(
    _$SignalDb db,
    $SignalSignedPrekeysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSignedPrekeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSignedPrekeysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalSignedPrekeysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> signedPrekeyId = const Value.absent(),
                Value<Uint8List> record = const Value.absent(),
              }) => SignalSignedPrekeysCompanion(
                signedPrekeyId: signedPrekeyId,
                record: record,
              ),
          createCompanionCallback:
              ({
                Value<int> signedPrekeyId = const Value.absent(),
                required Uint8List record,
              }) => SignalSignedPrekeysCompanion.insert(
                signedPrekeyId: signedPrekeyId,
                record: record,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSignedPrekeysTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDb,
      $SignalSignedPrekeysTable,
      SignalSignedPrekey,
      $$SignalSignedPrekeysTableFilterComposer,
      $$SignalSignedPrekeysTableOrderingComposer,
      $$SignalSignedPrekeysTableAnnotationComposer,
      $$SignalSignedPrekeysTableCreateCompanionBuilder,
      $$SignalSignedPrekeysTableUpdateCompanionBuilder,
      (
        SignalSignedPrekey,
        BaseReferences<
          _$SignalDb,
          $SignalSignedPrekeysTable,
          SignalSignedPrekey
        >,
      ),
      SignalSignedPrekey,
      PrefetchHooks Function()
    >;
typedef $$SignalIdentitiesTableCreateCompanionBuilder =
    SignalIdentitiesCompanion Function({
      required String name,
      required int deviceNum,
      required Uint8List identityKey,
      Value<DateTime> firstSeen,
      Value<int> rowid,
    });
typedef $$SignalIdentitiesTableUpdateCompanionBuilder =
    SignalIdentitiesCompanion Function({
      Value<String> name,
      Value<int> deviceNum,
      Value<Uint8List> identityKey,
      Value<DateTime> firstSeen,
      Value<int> rowid,
    });

class $$SignalIdentitiesTableFilterComposer
    extends Composer<_$SignalDb, $SignalIdentitiesTable> {
  $$SignalIdentitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalIdentitiesTableOrderingComposer
    extends Composer<_$SignalDb, $SignalIdentitiesTable> {
  $$SignalIdentitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalIdentitiesTableAnnotationComposer
    extends Composer<_$SignalDb, $SignalIdentitiesTable> {
  $$SignalIdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get deviceNum =>
      $composableBuilder(column: $table.deviceNum, builder: (column) => column);

  GeneratedColumn<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);
}

class $$SignalIdentitiesTableTableManager
    extends
        RootTableManager<
          _$SignalDb,
          $SignalIdentitiesTable,
          SignalIdentity,
          $$SignalIdentitiesTableFilterComposer,
          $$SignalIdentitiesTableOrderingComposer,
          $$SignalIdentitiesTableAnnotationComposer,
          $$SignalIdentitiesTableCreateCompanionBuilder,
          $$SignalIdentitiesTableUpdateCompanionBuilder,
          (
            SignalIdentity,
            BaseReferences<_$SignalDb, $SignalIdentitiesTable, SignalIdentity>,
          ),
          SignalIdentity,
          PrefetchHooks Function()
        > {
  $$SignalIdentitiesTableTableManager(
    _$SignalDb db,
    $SignalIdentitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalIdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalIdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalIdentitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> deviceNum = const Value.absent(),
                Value<Uint8List> identityKey = const Value.absent(),
                Value<DateTime> firstSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalIdentitiesCompanion(
                name: name,
                deviceNum: deviceNum,
                identityKey: identityKey,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int deviceNum,
                required Uint8List identityKey,
                Value<DateTime> firstSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalIdentitiesCompanion.insert(
                name: name,
                deviceNum: deviceNum,
                identityKey: identityKey,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalIdentitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDb,
      $SignalIdentitiesTable,
      SignalIdentity,
      $$SignalIdentitiesTableFilterComposer,
      $$SignalIdentitiesTableOrderingComposer,
      $$SignalIdentitiesTableAnnotationComposer,
      $$SignalIdentitiesTableCreateCompanionBuilder,
      $$SignalIdentitiesTableUpdateCompanionBuilder,
      (
        SignalIdentity,
        BaseReferences<_$SignalDb, $SignalIdentitiesTable, SignalIdentity>,
      ),
      SignalIdentity,
      PrefetchHooks Function()
    >;
typedef $$SignalIdentityChangesTableCreateCompanionBuilder =
    SignalIdentityChangesCompanion Function({
      Value<int> id,
      required String name,
      required int deviceNum,
      Value<DateTime> changedAt,
    });
typedef $$SignalIdentityChangesTableUpdateCompanionBuilder =
    SignalIdentityChangesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> deviceNum,
      Value<DateTime> changedAt,
    });

class $$SignalIdentityChangesTableFilterComposer
    extends Composer<_$SignalDb, $SignalIdentityChangesTable> {
  $$SignalIdentityChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalIdentityChangesTableOrderingComposer
    extends Composer<_$SignalDb, $SignalIdentityChangesTable> {
  $$SignalIdentityChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceNum => $composableBuilder(
    column: $table.deviceNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalIdentityChangesTableAnnotationComposer
    extends Composer<_$SignalDb, $SignalIdentityChangesTable> {
  $$SignalIdentityChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get deviceNum =>
      $composableBuilder(column: $table.deviceNum, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);
}

class $$SignalIdentityChangesTableTableManager
    extends
        RootTableManager<
          _$SignalDb,
          $SignalIdentityChangesTable,
          SignalIdentityChange,
          $$SignalIdentityChangesTableFilterComposer,
          $$SignalIdentityChangesTableOrderingComposer,
          $$SignalIdentityChangesTableAnnotationComposer,
          $$SignalIdentityChangesTableCreateCompanionBuilder,
          $$SignalIdentityChangesTableUpdateCompanionBuilder,
          (
            SignalIdentityChange,
            BaseReferences<
              _$SignalDb,
              $SignalIdentityChangesTable,
              SignalIdentityChange
            >,
          ),
          SignalIdentityChange,
          PrefetchHooks Function()
        > {
  $$SignalIdentityChangesTableTableManager(
    _$SignalDb db,
    $SignalIdentityChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalIdentityChangesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SignalIdentityChangesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalIdentityChangesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> deviceNum = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => SignalIdentityChangesCompanion(
                id: id,
                name: name,
                deviceNum: deviceNum,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int deviceNum,
                Value<DateTime> changedAt = const Value.absent(),
              }) => SignalIdentityChangesCompanion.insert(
                id: id,
                name: name,
                deviceNum: deviceNum,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalIdentityChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDb,
      $SignalIdentityChangesTable,
      SignalIdentityChange,
      $$SignalIdentityChangesTableFilterComposer,
      $$SignalIdentityChangesTableOrderingComposer,
      $$SignalIdentityChangesTableAnnotationComposer,
      $$SignalIdentityChangesTableCreateCompanionBuilder,
      $$SignalIdentityChangesTableUpdateCompanionBuilder,
      (
        SignalIdentityChange,
        BaseReferences<
          _$SignalDb,
          $SignalIdentityChangesTable,
          SignalIdentityChange
        >,
      ),
      SignalIdentityChange,
      PrefetchHooks Function()
    >;

class $SignalDbManager {
  final _$SignalDb _db;
  $SignalDbManager(this._db);
  $$SignalSessionsTableTableManager get signalSessions =>
      $$SignalSessionsTableTableManager(_db, _db.signalSessions);
  $$SignalPrekeysTableTableManager get signalPrekeys =>
      $$SignalPrekeysTableTableManager(_db, _db.signalPrekeys);
  $$SignalSignedPrekeysTableTableManager get signalSignedPrekeys =>
      $$SignalSignedPrekeysTableTableManager(_db, _db.signalSignedPrekeys);
  $$SignalIdentitiesTableTableManager get signalIdentities =>
      $$SignalIdentitiesTableTableManager(_db, _db.signalIdentities);
  $$SignalIdentityChangesTableTableManager get signalIdentityChanges =>
      $$SignalIdentityChangesTableTableManager(_db, _db.signalIdentityChanges);
}
