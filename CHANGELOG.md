## 1.0.0

- Added `Patch<T>`, a sealed wrapper for `copyWith` arguments that tells an
  omitted argument apart from one supplied as `null`.
- Added the `Value<T>` and `Unchanged<T>` variants, which respectively replace a
  field and leave it alone.
- Added `Clear`, a `Value<Null>` naming the intent to null out a field. It
  satisfies `Patch<T?>` but no `Patch<T>`, so clearing a non-nullable field is a
  compile error, and a `Value(...)` pattern already matches it.
- Added `resolve`, an extension method on `Patch<T>` folding a patch against a
  field's current value, so a `copyWith` body needs no switch. It is an
  extension rather than a method so that clearing a populated field does not
  trip Dart's covariance check on `Clear`'s `Null` type argument.
- Added `==` and `hashCode` to the variants. Equality is by wrapped value and
  ignores type arguments, so `Value('a') == Value('a')`, all `Unchanged`s are
  equal, and `Clear() == Value(null)`.
