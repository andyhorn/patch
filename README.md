# patch

A wrapper for `copyWith` arguments, so that a nullable field can be set to `null` or left unchanged.

In a typical `copyWith`, a nullable field cannot be assigned to `null` - it would read the same as "unchanged."

## Getting started

```sh
dart pub add patch
```

Or add it to your `pubspec.yaml` directly:

```yaml
dependencies:
  patch: ^1.0.0
```

Requires Dart 3.7 or later.

## Usage

Declare each `copyWith` parameter as a `Patch` that defaults to `Unchanged`, and `resolve` it against the field's **current** value:

```dart
import 'package:patch/patch.dart';

class UserProfile {
  UserProfile(this.name, this.nickname);

  final String name;
  final String? nickname;
}

extension on UserProfile {
  UserProfile copyWith({
    Patch<String?> nickname = const Unchanged(),
  }) {
    return UserProfile(
      name,
      nickname.resolve(this.nickname),
    );
  }
}
```

All three outcomes are reachable:

```dart
final profile = UserProfile('Ada Lovelace', 'Ada');

profile.copyWith().nickname;                                // 'Ada'
profile.copyWith(nickname: Value('The Countess')).nickname; // 'The Countess'
// Because nickname is nullable, we can also "Clear" it
profile.copyWith(nickname: const Clear()).nickname;         // null
```

For a runnable version, see `example/patch_example.dart`.

### `.resolve`

`resolve` is just a helper that picks the new value, when provided, or the current value otherwise.

```dart
final resolved = switch (nickname) {
  Value(value: final v) => v,
  Unchanged() => this.nickname,
};
```

## The variants

| Variant | The caller | The field becomes |
| --- | --- | --- |
| `Value(v)` | passed a value | `v` |
| `Unchanged()` | passed nothing | unchanged |
| `Clear()` | asked to remove the value | `null` |

### Clear

`Clear` is just a special case of `Value<Null>` to more clearly indicate its intent. Attempting to assign `Clear` to a non-nullable value results in a compile-time error. You do not need to handle a `Clear()` in a `switch` for it to be exhaustive.

## Non-nullable fields

A non-nullable parameter uses the same API:

```dart
name.resolve(this.name)
```

Mentioned above, clearing a non-nullable field does not pass type-checking:

```dart
profile.copyWith(name: const Clear());
//                     ^ The argument type 'Clear' can't be assigned to the
//                       parameter type 'Patch<String>'.
```

## Strong typing

The type argument in a `Patch` is necessary. A bare `Patch` becomes a `Patch<dynamic>`, which accepts a `Clear` no matter what the field's type actually is. This opens the door for runtime errors. Enable `strict-raw-types` in your `analysis_options.yaml` to catch this.

```yaml
analyzer:
  language:
    strict-raw-types: true
```

## Why `resolve` is an extension

`Clear` is a `Value<Null>`. If `resolve` were a real method on `Patch<T>`, then calling it on a `Clear` would type `current` as `Null`, and clearing a populated field would throw. Extensions are dispatched statically, so `current` gets its type from the call site instead.

The cost is that you have to call it on something typed `Patch<T?>`:

```dart
const Clear().resolve('Ada');            // T infers as Null, so this won't compile

final Patch<String?> patch = const Clear();
patch.resolve('Ada');                    // null
```

`copyWith` parameters are already `Patch<T?>`, so you rarely hit this.

## Equality

The variants are value types, so two separate `Value` instances with the same value are equal. All `Unchanged` are equal to each other, too. This allows `Patch`es to compare and hash and even work as `Map` keys and `Set` members.

```dart
Value('a') == Value('a');             // true
Value<Object>('a') == Value('a');     // true - equality is based on the _value_, not the type
const Unchanged<String>() == const Unchanged<int>(); // true
const Unchanged<String?>() == Value<String?>(null);  // false
```

Note: since `Clear()` *is* `Value(null)`, the two are equal.

```dart
const Clear() == Value<String?>(null); // true
```

Use `is Clear` when you need to tell an explicit clear apart from an incidental `null` - equality will not do it for you.
