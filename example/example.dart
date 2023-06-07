import 'package:xdg_locale/xdg_locale.dart';

void main() async {
  final service = XdgLocaleClient();
  await service.connect();
  print('X11 keyboard layout: ${service.x11Layout}');
  print('X11 keyboard variant: ${service.x11Variant}');
  await service.close();
}
