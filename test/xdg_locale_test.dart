import 'package:dbus/dbus.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:xdg_locale/xdg_locale.dart';

import 'xdg_locale_test.mocks.dart';

@GenerateMocks([DBusClient, DBusRemoteObject])
void main() {
  final interfaceName = XdgLocaleService.interfaceName;
  test('connect and disconnect', () async {
    final object = createMockRemoteObject();
    final bus = object.client as MockDBusClient;

    final service = XdgLocaleService(object: object);
    await service.connect();
    verify(object.getAllProperties(interfaceName)).called(1);

    await service.close();
    verify(bus.close()).called(1);
  });

  test('read properties', () async {
    final object = createMockRemoteObject(properties: {
      'Locale': DBusArray.string([
        'LANG=en_US.UTF-8',
        'LC_DATE=en_GB.UTF-8',
      ]),
      'VConsoleKeymap': const DBusString('us'),
      'VConsoleKeymapToggle': const DBusString('de'),
      'X11Layout': const DBusString('us'),
      'X11Model': const DBusString('pc105'),
      'X11Variant': const DBusString('altgr-intl'),
      'X11Options': const DBusString('terminate:ctrl_alt_bksp'),
    });

    final service = XdgLocaleService(object: object);
    await service.connect();
    expect(
        service.locale,
        equals({
          'LANG': 'en_US.UTF-8',
          'LC_DATE': 'en_GB.UTF-8',
        }));
    expect(service.vConsoleKeymap, equals('us'));
    expect(service.vConsoleKeymapToggle, equals('de'));
    expect(service.x11Layout, equals('us'));
    expect(service.x11Model, equals('pc105'));
    expect(service.x11Variant, equals('altgr-intl'));
    expect(service.x11Options, equals('terminate:ctrl_alt_bksp'));
    await service.close();
  });

  test('call methods', () async {
    final object = createMockRemoteObject();
    final service = XdgLocaleService(object: object);

    await service.setLocale(
      {'LANG': 'en_US.UTF-8', 'LC_DATE': 'en_GB.UTF-8'},
      false,
    );
    verify(object.callMethod(
      interfaceName,
      'SetLocale',
      [
        DBusArray.string(['LANG=en_US.UTF-8', 'LC_DATE=en_GB.UTF-8']),
        const DBusBoolean(false),
      ],
      replySignature: DBusSignature.empty,
    )).called(1);

    await service.setVConsoleKeyboard('us', 'de', false, false);
    verify(object.callMethod(
      interfaceName,
      'SetVConsoleKeyboard',
      const [
        DBusString('us'),
        DBusString('de'),
        DBusBoolean(false),
        DBusBoolean(false)
      ],
      replySignature: DBusSignature.empty,
    )).called(1);

    await service.setX11Keyboard(
      'us',
      'pc105',
      'altgr-intl',
      'terminate:ctrl_alt_bksp',
      true,
      true,
    );
    verify(object.callMethod(
      interfaceName,
      'SetX11Keyboard',
      const [
        DBusString('us'),
        DBusString('pc105'),
        DBusString('altgr-intl'),
        DBusString('terminate:ctrl_alt_bksp'),
        DBusBoolean(true),
        DBusBoolean(true)
      ],
      replySignature: DBusSignature.empty,
    )).called(1);
  });
}

MockDBusRemoteObject createMockRemoteObject({
  Stream<DBusPropertiesChangedSignal>? propertiesChanged,
  Map<String, DBusValue>? properties,
}) {
  final bus = MockDBusClient();
  final object = MockDBusRemoteObject();
  final interfaceName = XdgLocaleService.interfaceName;

  when(object.client).thenReturn(bus);
  when(object.propertiesChanged)
      .thenAnswer((_) => propertiesChanged ?? const Stream.empty());
  when(object.getAllProperties(interfaceName))
      .thenAnswer((_) async => properties ?? {});
  when(object.callMethod(interfaceName, any, any,
          replySignature: DBusSignature.empty))
      .thenAnswer((i) async {
    if ([
      'SetLocale',
      'SetVConsoleKeyboard',
      'SetX11Keyboard',
    ].contains(i.positionalArguments[1])) {
      return DBusMethodSuccessResponse();
    }
    throw DBusMethodResponseException(
        DBusMethodErrorResponse.unknownMethod(i.positionalArguments[1]));
  });
  return object;
}
