import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

enum PumpKind { hot, cold }

enum PumpControlMode { auto, manual }

enum AquaSensorKind { temperature, ph }

extension PumpKindPath on PumpKind {
  String get firebasePath {
    switch (this) {
      case PumpKind.hot:
        return 'hot';
      case PumpKind.cold:
        return 'cold';
    }
  }

  String get esp32Key {
    switch (this) {
      case PumpKind.hot:
        return 'hotPump';
      case PumpKind.cold:
        return 'coldPump';
    }
  }

  PumpKind get opposite {
    switch (this) {
      case PumpKind.hot:
        return PumpKind.cold;
      case PumpKind.cold:
        return PumpKind.hot;
    }
  }

  List<String> get thresholdKeys {
    switch (this) {
      case PumpKind.hot:
        return const [
          'hotPumpThreshold',
          'hotPumpThresholdC',
          'hotThreshold',
          'hotThresholdC',
        ];
      case PumpKind.cold:
        return const [
          'coldPumpThreshold',
          'coldPumpThresholdC',
          'coldThreshold',
          'coldThresholdC',
        ];
    }
  }
}

extension AquaSensorKindPaths on AquaSensorKind {
  List<String> get historyPaths {
    switch (this) {
      case AquaSensorKind.temperature:
        return const [
          'esp32/history/items',
          'esp32/history/temperatureC',
          'esp32/history/temperature',
          'esp32/history/tempC',
          'esp32/history/temp',
          'esp32/history',
          'history/temperature',
          'history/temp',
          'histories/temperature',
          'readings/temperature',
          'sensorHistory/temperature',
          'sensor_history/temperature',
          'logs/temperature',
          'sensors/temperature/history',
          'sensors/temp/history',
          'lichSu/nhietDo',
          'lich_su/nhiet_do',
        ];
      case AquaSensorKind.ph:
        return const [
          'esp32/history/ph',
          'esp32/history/pH',
          'esp32/history/phValue',
          'esp32/history/pHValue',
          'esp32/history',
          'history/ph',
          'history/pH',
          'histories/ph',
          'histories/pH',
          'readings/ph',
          'readings/pH',
          'sensorHistory/ph',
          'sensorHistory/pH',
          'sensor_history/ph',
          'logs/ph',
          'logs/pH',
          'sensors/ph/history',
          'sensors/pH/history',
          'lichSu/ph',
          'lich_su/ph',
        ];
    }
  }
}

class AquaRealtimeData {
  final double? temperature;
  final double? ph;
  final bool hotPumpOn;
  final bool coldPumpOn;
  final double hotPumpThreshold;
  final double coldPumpThreshold;
  final PumpControlMode controlMode;

  const AquaRealtimeData({
    this.temperature,
    this.ph,
    this.hotPumpOn = false,
    this.coldPumpOn = false,
    this.hotPumpThreshold = 25,
    this.coldPumpThreshold = 32,
    this.controlMode = PumpControlMode.auto,
  });

  factory AquaRealtimeData.fromFirebase(Object? value) {
    final data = _toStringMap(value);

    return AquaRealtimeData(
      temperature: _readDouble(data, const [
        'esp32/current/temperatureC',
        'esp32/current/tempC',
        'esp32/current/temperature',
        'esp32/current/temp',
        'sensors/temperature',
        'sensors/temp',
        'sensor/temperature',
        'temperature',
        'temp',
        'nhietDo',
        'nhiet_do',
      ]),
      ph: _readDouble(data, const [
        'esp32/current/ph',
        'esp32/current/pH',
        'esp32/current/phValue',
        'esp32/current/pHValue',
        'sensors/ph',
        'sensors/pH',
        'sensor/ph',
        'sensor/pH',
        'ph',
        'pH',
      ]),
      hotPumpOn:
          _readBool(data, const [
            'esp32/current/hotPump',
            'esp32/control/hotPump',
            'esp32/config/hotPump',
            'pumps/hot/isOn',
            'pumps/hot/on',
            'devices/hotPump/isOn',
            'hotPump/isOn',
            'hotPump',
            'bomNong',
            'bom_nong',
          ]) ??
          false,
      coldPumpOn:
          _readBool(data, const [
            'esp32/current/coldPump',
            'esp32/control/coldPump',
            'esp32/config/coldPump',
            'pumps/cold/isOn',
            'pumps/cold/on',
            'devices/coldPump/isOn',
            'coldPump/isOn',
            'coldPump',
            'bomLanh',
            'bom_lanh',
          ]) ??
          false,
      hotPumpThreshold:
          _readDouble(data, const [
            'esp32/config/hotPumpThreshold',
            'esp32/config/hotPumpThresholdC',
            'esp32/config/hotThreshold',
            'esp32/config/hotThresholdC',
            'esp32/current/hotPumpThreshold',
            'esp32/current/hotPumpThresholdC',
            'esp32/current/hotThreshold',
            'esp32/current/hotThresholdC',
            'pumps/hot/threshold',
            'settings/hotPumpThreshold',
            'thresholds/hotPump',
            'nguong/bomNong',
            'nguong_bom_nong',
          ]) ??
          25,
      coldPumpThreshold:
          _readDouble(data, const [
            'esp32/config/coldPumpThreshold',
            'esp32/config/coldPumpThresholdC',
            'esp32/config/coldThreshold',
            'esp32/config/coldThresholdC',
            'esp32/current/coldPumpThreshold',
            'esp32/current/coldPumpThresholdC',
            'esp32/current/coldThreshold',
            'esp32/current/coldThresholdC',
            'pumps/cold/threshold',
            'settings/coldPumpThreshold',
            'thresholds/coldPump',
            'nguong/bomLanh',
            'nguong_bom_lanh',
          ]) ??
          32,
      controlMode:
          _readMode(data, const [
            'esp32/config/mode',
            'esp32/control/mode',
            'pumps/mode',
            'settings/pumpMode',
            'mode',
          ]) ??
          PumpControlMode.auto,
    );
  }

  static Map<String, dynamic> _toStringMap(Object? value) {
    if (value is! Map) {
      return const {};
    }

    return value.map((key, childValue) {
      final normalizedValue = childValue is Map
          ? _toStringMap(childValue)
          : childValue;
      return MapEntry(key.toString(), normalizedValue);
    });
  }

  static Object? _readPath(Map<String, dynamic> data, String path) {
    Object? current = data;

    for (final segment in path.split('/')) {
      if (current is Map<String, dynamic>) {
        current = current[segment];
      } else if (current is Map) {
        current = current[segment] ?? current[segment.toLowerCase()];
      } else {
        return null;
      }
    }

    return current;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> paths) {
    for (final path in paths) {
      final value = _asDouble(_readPath(data, path));
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    if (value is Map) {
      for (final key in const ['value', 'current', 'last', 'reading']) {
        final nestedValue = value[key];
        final parsed = _asDouble(nestedValue);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static bool? _readBool(Map<String, dynamic> data, List<String> paths) {
    for (final path in paths) {
      final value = _asBool(_readPath(data, path));
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static PumpControlMode? _readMode(
    Map<String, dynamic> data,
    List<String> paths,
  ) {
    for (final path in paths) {
      final value = _asMode(_readPath(data, path));
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static PumpControlMode? _asMode(Object? value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (const [
        'auto',
        'automatic',
        'tu_dong',
        'tự động',
      ].contains(normalized)) {
        return PumpControlMode.auto;
      }
      if (const ['manual', 'thu_cong', 'thủ công'].contains(normalized)) {
        return PumpControlMode.manual;
      }
    }

    if (value is bool) {
      return value ? PumpControlMode.auto : PumpControlMode.manual;
    }

    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (const [
        'true',
        '1',
        'on',
        'active',
        'running',
        'bat',
      ].contains(normalized)) {
        return true;
      }
      if (const [
        'false',
        '0',
        'off',
        'inactive',
        'stopped',
        'tat',
      ].contains(normalized)) {
        return false;
      }
    }

    if (value is Map) {
      for (final key in const ['isOn', 'on', 'state', 'value']) {
        final parsed = _asBool(value[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}

class AquaHistoryEntry {
  final double value;
  final DateTime? measuredAt;
  final String? label;

  const AquaHistoryEntry({required this.value, this.measuredAt, this.label});

  static List<AquaHistoryEntry> fromFirebaseRoot(
    Object? value,
    AquaSensorKind sensorKind,
  ) {
    final data = AquaRealtimeData._toStringMap(value);

    for (final path in sensorKind.historyPaths) {
      final entries = _fromFirebaseValue(
        AquaRealtimeData._readPath(data, path),
        sensorKind,
      );
      if (entries.isNotEmpty) {
        return entries;
      }
    }

    return const [];
  }

  static List<AquaHistoryEntry> _fromFirebaseValue(
    Object? value,
    AquaSensorKind sensorKind,
  ) {
    final entries = <AquaHistoryEntry>[];

    if (value is List) {
      for (var i = 0; i < value.length; i += 1) {
        final entry = _parseEntry(i.toString(), value[i], sensorKind);
        if (entry != null) {
          entries.add(entry);
        }
      }
    } else if (value is Map) {
      value.forEach((key, childValue) {
        final entry = _parseEntry(key.toString(), childValue, sensorKind);
        if (entry != null) {
          entries.add(entry);
        }
      });
    } else {
      final entry = _parseEntry(null, value, sensorKind);
      if (entry != null) {
        entries.add(entry);
      }
    }

    entries.sort((a, b) {
      final aTime = a.measuredAt;
      final bTime = b.measuredAt;
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return -1;
      }
      if (bTime == null) {
        return 1;
      }
      return aTime.compareTo(bTime);
    });

    return entries;
  }

  static AquaHistoryEntry? _parseEntry(
    String? key,
    Object? value,
    AquaSensorKind sensorKind,
  ) {
    if (value is Map) {
      final data = AquaRealtimeData._toStringMap(value);
      final reading = _firstDouble(data, _valueKeys(sensorKind));
      if (reading == null) {
        return null;
      }

      final rawTime = _firstValue(data, const [
        'timestamp',
        'timeStamp',
        'createdAt',
        'time',
        'date',
        'measuredAt',
      ]);
      final measuredAt = _asDateTime(rawTime) ?? _asDateTime(key);
      final label = _asLabel(rawTime) ?? _asLabel(key);

      return AquaHistoryEntry(
        value: reading,
        measuredAt: measuredAt,
        label: label,
      );
    }

    final reading = AquaRealtimeData._asDouble(value);
    if (reading == null) {
      return null;
    }

    return AquaHistoryEntry(
      value: reading,
      measuredAt: _asDateTime(key),
      label: _asLabel(key),
    );
  }

  static List<String> _valueKeys(AquaSensorKind sensorKind) {
    switch (sensorKind) {
      case AquaSensorKind.temperature:
        return const [
          'temperatureC',
          'tempC',
          'temperature',
          'temp',
          'nhietDo',
          'nhiet_do',
          'value',
          'val',
          'current',
          'reading',
        ];
      case AquaSensorKind.ph:
        return const [
          'ph',
          'pH',
          'phValue',
          'pHValue',
          'value',
          'val',
          'current',
          'reading',
        ];
    }
  }

  static double? _firstDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = AquaRealtimeData._asDouble(data[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static Object? _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is num) {
      final milliseconds = value > 9999999999
          ? value.toInt()
          : value.toInt() * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    if (value is String) {
      final numeric = num.tryParse(value);
      if (numeric != null) {
        return _asDateTime(numeric);
      }
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String? _asLabel(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final looksLikeTimestamp = num.tryParse(trimmed) != null;
    final looksLikeIsoDate = DateTime.tryParse(trimmed) != null;
    if (looksLikeTimestamp || looksLikeIsoDate) {
      return null;
    }

    return trimmed;
  }
}

class AquaChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime? createdAt;
  final bool isLocal;

  const AquaChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    this.createdAt,
    this.isLocal = false,
  });

  factory AquaChatMessage.user(String text) {
    return AquaChatMessage(text: text, isUser: true, createdAt: DateTime.now());
  }

  factory AquaChatMessage.assistant(String text) {
    return AquaChatMessage(
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
    );
  }

  factory AquaChatMessage.localAssistant(String text) {
    return AquaChatMessage(
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
      isLocal: true,
    );
  }

  String get geminiRole => isUser ? 'user' : 'model';

  Map<String, Object?> toFirebase() {
    return {
      'text': text,
      'sender': isUser ? 'user' : 'assistant',
      'isUser': isUser,
      'createdAt': ServerValue.timestamp,
    };
  }

  static List<AquaChatMessage> listFromFirebase(Object? value) {
    if (value is! Map) {
      return const [];
    }

    final messages = <AquaChatMessage>[];
    value.forEach((key, childValue) {
      final message = _fromFirebaseEntry(key.toString(), childValue);
      if (message != null) {
        messages.add(message);
      }
    });

    messages.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) {
        return (a.id ?? '').compareTo(b.id ?? '');
      }
      if (aTime == null) {
        return -1;
      }
      if (bTime == null) {
        return 1;
      }
      return aTime.compareTo(bTime);
    });

    return messages;
  }

  static AquaChatMessage? _fromFirebaseEntry(String id, Object? value) {
    if (value is! Map) {
      return null;
    }

    final data = AquaRealtimeData._toStringMap(value);
    final text = (data['text'] ?? data['message'] ?? data['content'])
        ?.toString()
        .trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final sender = data['sender']?.toString().trim().toLowerCase();
    final isUser =
        AquaRealtimeData._asBool(data['isUser']) ??
        (sender == 'user' || sender == 'human');

    return AquaChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      createdAt: AquaHistoryEntry._asDateTime(data['createdAt']),
    );
  }
}

class AquaFirebaseService {
  static const String _databaseUrl =
      'https://thuy-san-91d35-default-rtdb.firebaseio.com';
  static const String _basePath = 'thuy-san';

  AquaFirebaseService({FirebaseDatabase? database})
    : _root =
          (database ??
                  FirebaseDatabase.instanceFor(
                    app: Firebase.app(),
                    databaseURL: _databaseUrl,
                  ))
              .ref(_basePath);

  final DatabaseReference _root;

  Stream<AquaRealtimeData> watchRealtimeData() {
    return _root.onValue.map(
      (event) => AquaRealtimeData.fromFirebase(event.snapshot.value),
    );
  }

  Future<AquaRealtimeData> readRealtimeDataOnce() async {
    final snapshot = await _root.get();
    return AquaRealtimeData.fromFirebase(snapshot.value);
  }

  Stream<List<AquaHistoryEntry>> watchSensorHistory(AquaSensorKind sensorKind) {
    return _root.onValue.map(
      (event) =>
          AquaHistoryEntry.fromFirebaseRoot(event.snapshot.value, sensorKind),
    );
  }

  Stream<List<AquaChatMessage>> watchChatMessages({int limit = 60}) {
    return _root.child('chatbot/messages').onValue.map((event) {
      final messages = AquaChatMessage.listFromFirebase(event.snapshot.value);
      if (messages.length <= limit) {
        return messages;
      }
      return messages.sublist(messages.length - limit);
    });
  }

  Future<void> saveChatMessage(AquaChatMessage message) {
    return _root.child('chatbot/messages').push().set(message.toFirebase());
  }

  Future<void> clearChatMessages() {
    return _root.child('chatbot/messages').remove();
  }

  Future<void> setPumpState(PumpKind pump, bool isOn) {
    final timestamp = ServerValue.timestamp;
    final oppositePump = pump.opposite;

    return _root.update({
      'esp32/config/mode': 'manual',
      'esp32/config/autoMode': false,
      'esp32/config/manualMode': true,
      'esp32/config/configLoaded': false,
      'esp32/current/${pump.esp32Key}': isOn,
      'esp32/control/${pump.esp32Key}': isOn,
      'esp32/control/mode': 'manual',
      'esp32/control/updatedAt': timestamp,
      'pumps/${pump.firebasePath}/isOn': isOn,
      'pumps/mode': 'manual',
      'pumps/${pump.firebasePath}/updatedAt': timestamp,
      if (isOn) ...{
        'esp32/current/${oppositePump.esp32Key}': false,
        'esp32/control/${oppositePump.esp32Key}': false,
        'pumps/${oppositePump.firebasePath}/isOn': false,
        'pumps/${oppositePump.firebasePath}/updatedAt': timestamp,
      },
    });
  }

  Future<void> setPumpThreshold(PumpKind pump, double threshold) {
    final timestamp = ServerValue.timestamp;
    final updates = <String, Object?>{
      'esp32/config/mode': 'auto',
      'esp32/config/autoMode': true,
      'esp32/config/manualMode': false,
      'esp32/config/configLoaded': false,
      'esp32/config/updatedAt': timestamp,
      'esp32/control/mode': 'auto',
      'pumps/mode': 'auto',
      'pumps/${pump.firebasePath}/mode': 'auto',
      'pumps/${pump.firebasePath}/threshold': threshold,
      'pumps/${pump.firebasePath}/updatedAt': timestamp,
    };

    for (final key in pump.thresholdKeys) {
      updates['esp32/config/$key'] = threshold;
    }

    return _root.update(updates);
  }

  Future<void> setControlMode(PumpControlMode mode) {
    final timestamp = ServerValue.timestamp;
    final isAuto = mode == PumpControlMode.auto;
    final modeValue = isAuto ? 'auto' : 'manual';

    return _root.update({
      'esp32/config/mode': modeValue,
      'esp32/config/autoMode': isAuto,
      'esp32/config/manualMode': !isAuto,
      'esp32/config/configLoaded': false,
      'esp32/config/updatedAt': timestamp,
      'esp32/control/mode': modeValue,
      'esp32/control/updatedAt': timestamp,
      'pumps/mode': modeValue,
      if (isAuto) ...{
        'esp32/config/hotPumpThreshold': 25,
        'esp32/config/hotPumpThresholdC': 25,
        'esp32/config/hotThreshold': 25,
        'esp32/config/hotThresholdC': 25,
        'esp32/config/coldPumpThreshold': 32,
        'esp32/config/coldPumpThresholdC': 32,
        'esp32/config/coldThreshold': 32,
        'esp32/config/coldThresholdC': 32,
        'pumps/hot/threshold': 25,
        'pumps/cold/threshold': 32,
      },
    });
  }
}
