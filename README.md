# xdg_locale.dart
Native Dart client library to access the [D-Bus interface of systemd-localed](https://www.freedesktop.org/software/systemd/man/org.freedesktop.locale1.html).

[![CI](https://github.com/canonical/xdg_locale.dart/workflows/Tests/badge.svg)](https://github.com/canonical/xdg_locale.dart/actions/workflows/tests.yaml)
[![codecov](https://codecov.io/gh/canonical/xdg_locale.dart/branch/main/graph/badge.svg)](https://codecov.io/gh/canonical/xdg_locale.dart)

## Example

```dart
import 'package:xdg_locale/xdg_locale.dart';

void main() async {
  final service = XdgLocaleClient();
  await service.connect();
  print('X11 keyboard layout: ${service.x11Layout}');
  print('X11 keyboard variant: ${service.x11Variant}');
  await service.close();
}
```

## Contributing to xdg_locale.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.