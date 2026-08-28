import 'package:meta/meta.dart';

/// A wrapper for an argument that must distinguish "not supplied" from
/// "supplied as null".
///
/// Declare each `copyWith` parameter as a [Patch] defaulting to [Unchanged],
/// then `nickname.resolve(this.nickname)` in the body. The README and
/// `example/patch_example.dart` show it in full.
///
/// [resolve] folds the argument against the field's current value; switch over
/// the patch directly when a case needs to do more than pick a value. Clearing
/// the field is [Value] carrying `null`, spelled [Clear] at the call site, and
/// a `Patch<String>` rejects both spellings at compile time.
///
/// The README derives why each of these holds.
sealed class Patch<T> {
  const Patch._();
}

/// An argument that was supplied, carrying [value].
///
/// A `Value(...)` pattern also matches [Clear], whose [value] is `null`.
///
/// Two `Value`s are equal when their [value]s are, whatever their type
/// arguments, so `Clear()` equals `Value(null)`.
@immutable
final class Value<T> extends Patch<T> {
  /// Creates a supplied argument carrying [value].
  const Value(this.value) : super._();

  /// The supplied value.
  final T value;

  @override
  bool operator ==(Object other) => other is Value && other.value == value;

  @override
  int get hashCode => Object.hash(Value, value);

  @override
  String toString() => 'Value($value)';
}

/// An argument that was not supplied; the existing value should be kept.
///
/// All `Unchanged`s are equal, whatever their type arguments, and none is equal
/// to a [Value].
@immutable
final class Unchanged<T> extends Patch<T> {
  /// Creates an omitted argument.
  const Unchanged() : super._();

  @override
  bool operator ==(Object other) => other is Unchanged;

  @override
  int get hashCode => (Unchanged).hashCode;

  @override
  String toString() => 'Unchanged()';
}

/// An argument supplied to null out the field.
///
/// This is a `Value<Null>`, so it satisfies a `Patch<T?>` for any `T` and no
/// `Patch<T>` at all. Handling it needs no case of its own: a `Value(...)`
/// pattern matches it and binds `null`. Match `Clear()` ahead of `Value(...)`
/// only to treat an explicit clear differently from an incidental `null`.
final class Clear extends Value<Null> {
  /// Creates a clearing argument.
  const Clear() : super(null);

  @override
  String toString() => 'Clear()';
}

/// Folds a [Patch] against the value it is being applied to.
///
/// This is an extension rather than a method on [Patch] so that `current` is
/// typed by the call site rather than by [Clear]'s `Null` type argument. See
/// "Why `resolve` is an extension" in the README.
extension Resolve<T> on Patch<T> {
  /// The value this patch produces for a field currently holding [current].
  ///
  /// [Value] supplies its own value, [Clear] supplies `null`, and [Unchanged]
  /// gives [current] back.
  T resolve(T current) => switch (this) {
    Value(value: final v) => v,
    Unchanged() => current,
  };
}
