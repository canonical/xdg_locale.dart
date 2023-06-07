import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';

class XdgLocaleClient {
  XdgLocaleClient({
    DBusClient? bus,
    @visibleForTesting DBusRemoteObject? object,
  })  : _bus = bus,
        _object = object ?? _createRemoteObject(bus);

  static DBusRemoteObject _createRemoteObject(DBusClient? bus) {
    return DBusRemoteObject(
      bus ?? DBusClient.system(),
      name: busName,
      path: DBusObjectPath(objectPath),
    );
  }

  static final String busName = 'org.freedesktop.locale1';
  static final String interfaceName = busName;
  static final String objectPath = '/org/freedesktop/locale1';

  final DBusClient? _bus;
  final DBusRemoteObject _object;
  final _properties = <String, DBusValue>{};
  final _propertyController = StreamController<List<String>>.broadcast();
  StreamSubscription? _propertySubscription;

  /// The system locale.
  Map<String, String> get locale =>
      Map.fromEntries((_properties['Locale']?.asStringArray() ?? []).map((e) {
        final p = e.split('=');
        return MapEntry(p.first, p.last);
      }));

  /// The X11 keyboard layout.
  String get x11Layout => _getProperty('X11Layout', '');

  /// The X11 keyboard model.
  String get x11Model => _getProperty('X11Model', '');

  /// The X11 keyboard variant.
  String get x11Variant => _getProperty('X11Variant', '');

  /// The X11 keyboard options.
  String get x11Options => _getProperty('X11Options', '');

  /// The VConsole keymap.
  String get vConsoleKeymap => _getProperty('VConsoleKeymap', '');

  /// The VConsole toggle keymap (secondary keymap).
  String get vConsoleKeymapToggle => _getProperty('VConsoleKeymapToggle', '');

  /// Sets the system locale.
  Future<void> setLocale(Map<String, String> locale, bool interactive) {
    return _object.callMethod(
      interfaceName,
      'SetLocale',
      [
        DBusArray.string([
          for (final entry in locale.entries) '${entry.key}=${entry.value}'
        ]),
        DBusBoolean(interactive)
      ],
      replySignature: DBusSignature.empty,
    );
  }

  /// Sets the VConsole keyboard.
  Future<void> setVConsoleKeyboard(
    String keymap,
    String keymapToggle,
    bool convert,
    bool interactive,
  ) {
    return _object.callMethod(
      interfaceName,
      'SetVConsoleKeyboard',
      [
        DBusString(keymap),
        DBusString(keymapToggle),
        DBusBoolean(convert),
        DBusBoolean(interactive),
      ],
      replySignature: DBusSignature.empty,
    );
  }

  /// Sets the X11 keyboard.
  Future<void> setX11Keyboard(
    String layout,
    String model,
    String variant,
    String options,
    bool convert,
    bool interactive,
  ) {
    return _object.callMethod(
      interfaceName,
      'SetX11Keyboard',
      [
        DBusString(layout),
        DBusString(model),
        DBusString(variant),
        DBusString(options),
        DBusBoolean(convert),
        DBusBoolean(interactive),
      ],
      replySignature: DBusSignature.empty,
    );
  }

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged => _propertyController.stream;

  T _getProperty<T>(String name, T defaultValue) {
    return _properties.get(name) ?? defaultValue;
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertyController.add(properties.keys.toList());
  }

  /// Connects to the locale service.
  Future<void> connect() async {
    // Already connected
    if (_propertySubscription != null) {
      return;
    }
    _propertySubscription ??= _object.propertiesChanged.listen((signal) {
      if (signal.propertiesInterface == interfaceName) {
        _updateProperties(signal.changedProperties);
      }
    });
    return _object.getAllProperties(interfaceName).then(_updateProperties);
  }

  /// Closes connection to the locale service.
  Future<void> close() async {
    await _propertySubscription?.cancel();
    _propertySubscription = null;
    if (_bus == null) {
      await _object.client.close();
    }
  }
}

extension DbusProperties on Map<String, DBusValue> {
  T? get<T>(String key) => this[key]?.toNative() as T?;
}
