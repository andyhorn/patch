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
switch over it to produce the new value:

```dart
import 'package:patch/patch.dart';

class UserProfile(final String name, final String? nickname);

extension on UserProfile {
  UserProfile copyWith({
    Patch<String?> nickname = const Unchanged(),
  }) => UserProfile(
    name,
    switch (nickname) {
      Value(value: final v) => v,
      Unchanged() => this.nickname,
    },
  );
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

## The variants

| Variant | The caller | The field becomes |
| --- | --- | --- |
| `Value(v)` | passed a value | `v` |
| `Unchanged()` | passed nothing | unchanged |
| `Clear()` | asked to remove the value | `null` |

`Clear` is not a third case to handle. It is a `Value<Null>` — the constant
`Value(null)`, under a name that says what the call site means — so the
`Value(value: final v)` pattern already matches it and binds `null`. `Patch<T>`
is sealed with exactly two direct subtypes, so the two-case switch above is
exhaustive without a `default` clause, and a missed case is a compile error
rather than a silent fallthrough.

## Non-nullable fields

A non-nullable parameter uses the same API and the same two-case switch:

```dart
switch (name) {
  Value(value: final v) => v,
  Unchanged() => this.name,
}
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

## Two things to know

`Value(null)` and `Clear()` are the same thing, deliberately. The distinction
that earns its keep is between those and `Unchanged()`, and neither can be
confused with an omitted argument. If a particular `copyWith` does need to tell
an explicit clear apart from an incidental `null`, match `Clear()` *before*
`Value(...)` — the reverse order makes the `Clear` case unreachable, which the
analyzer reports.

The variants do not override `==`, so two separately constructed `Value('a')`
instances are not equal. Assert on the object your `copyWith` returns, not on
the `Patch` you passed in. The `const` forms of `Unchanged` and `Clear` are
canonicalized, so those are identical across call sites.
