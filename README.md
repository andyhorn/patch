# patch

A wrapper for `copyWith` arguments, so that a nullable field can be cleared as
well as replaced.

Dart's optional parameters cannot tell `copyWith()` apart from
`copyWith(nickname: null)`. Both arrive as `null`, so the usual `copyWith`
idiom can replace a field or leave it alone, but it can never set the field back
to `null`. `Patch<T>` separates those cases.

## Getting started

This package is not published on pub.dev. Depend on it from git:

```yaml
dependencies:
  patch:
    git:
      url: https://github.com/andyhorn/patch.git
```

Pin a release by adding a `ref`:

```yaml
dependencies:
  patch:
    git:
      url: https://github.com/andyhorn/patch.git
      ref: v1.0.0
```

To work on the package alongside a consumer, depend on a local checkout
instead:

```yaml
dependencies:
  patch:
    path: ../patch
```

It requires Dart 3.13 or later.

## Usage

Declare each `copyWith` parameter as a `Patch` that defaults to `Unchanged`, and
`resolve` it against the field's current value:

```dart
import 'package:patch/patch.dart';

class UserProfile(final String name, final String? nickname);

extension on UserProfile {
  UserProfile copyWith({
    Patch<String?> nickname = const Unchanged(),
  }) => UserProfile(name, nickname.resolve(this.nickname));
}
```

All three outcomes are reachable:

```dart
final profile = UserProfile('Ada Lovelace', 'Ada');

profile.copyWith().nickname;                                // 'Ada'
profile.copyWith(nickname: Value('The Countess')).nickname; // 'The Countess'
profile.copyWith(nickname: const Clear()).nickname;         // null
```

For a runnable version, see `example/patch_example.dart`.

`resolve` is the whole of the common case, but nothing is hidden behind it —
switch over the patch directly when a branch needs to do more than pick a value:

```dart
switch (nickname) {
  Value(value: final v) => v,
  Unchanged() => this.nickname,
}
```

## The variants

| Variant | The caller | The field becomes |
| --- | --- | --- |
| `Value(v)` | passed a value | `v` |
| `Unchanged()` | passed nothing | unchanged |
| `Clear()` | asked to remove the value | `null` |

`Clear` is not a third case to handle. It is a `Value<Null>` — the constant
`Value(null)`, under a name that says what the call site means — so the
`Value(value: final v)` pattern already matches it and binds `null`. `Patch<T>`
is sealed with exactly two direct subtypes, so a switch over `Value` and
`Unchanged` is exhaustive without a `default` clause, and a missed case is a
compile error rather than a silent fallthrough.

## Non-nullable fields

A non-nullable parameter uses the same API:

```dart
name.resolve(this.name)
```

Clearing such a field does not type-check, because `Clear` is a `Patch<Null>`
and `Null` is not a subtype of `String`:

```dart
profile.copyWith(name: const Clear());
//                     ^ The argument type 'Clear' can't be assigned to the
//                       parameter type 'Patch<String>'.
```

The same applies to spelling it out as `Value(null)`. Nothing has to be folded
into `Unchanged`, and there is no unreachable branch to write.

## Why `resolve` is an extension

`Clear` is a `Value<Null>`, so a `resolve` inherited from `Patch<T>` would take
`current` as `Null` and Dart's covariance check would throw the moment a
populated field was cleared — the package's whole reason for existing. Extension
methods are dispatched statically, so `current` is typed by the call site.

Two consequences: `resolve` is invisible through a `dynamic` receiver, and an
importing library that declares its own `resolve` on `Patch` shadows this one.
Both are cheap next to a runtime failure the analyzer cannot see.

## Two things to know

`Value(null)` and `Clear()` are the same thing, deliberately. The distinction
that earns its keep is between those and `Unchanged()`, and neither can be
confused with an omitted argument. If a particular `copyWith` does need to tell
an explicit clear apart from an incidental `null`, match `Clear()` *before*
`Value(...)` — the reverse order makes the `Clear` case unreachable, which the
analyzer reports.

The variants are value types. Two separately constructed `Value('a')` instances
are equal, all `Unchanged()`s are equal, and neither is equal to the other, so
patches compare, hash, and work as map keys and set members as you would expect:

```dart
Value('a') == Value('a');             // true
Value<Object>('a') == Value('a');     // true — the type argument is not part of it
const Unchanged<String>() == const Unchanged<int>(); // true
const Unchanged<String?>() == Value<String?>(null);  // false
```

Equality follows the paragraph above: since `Clear()` *is* `Value(null)`, the
two are equal.

```dart
const Clear() == Value<String?>(null); // true
```

Use `is Clear` when you need to tell an explicit clear apart from an incidental
`null` — equality will not do it for you.
