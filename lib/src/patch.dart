/// A wrapper for an argument that must distinguish "not supplied" from
/// "supplied as null".
///
/// Dart's optional parameters cannot tell `copyWith(value: null)` apart from
/// `copyWith()`, so a nullable field can never be cleared through the usual
/// `copyWith` idiom. Declaring the parameter as a [Patch] and defaulting it
/// to [Unchanged] makes the cases distinct:
///
/// ```dart
/// class Person(final String? nickname);
///
/// extension on Person {
///   Person copyWith({Patch<String?> nickname = const Unchanged()}) =>
///       Person(nickname.resolve(this.nickname));
/// }
/// ```
///
/// [resolve] folds the argument against the field's current value. Switch over
/// the patch directly instead when a case needs to do more than pick a value.
///
/// Clearing the field is [Value] carrying `null`, spelled [Clear] at the call
/// site. Because `null` inhabits only nullable types, a `Patch<String>` rejects
/// both spellings at compile time, and a switch over [Value] and [Unchanged] is
/// exhaustive with no unreachable case to write.
sealed class Patch<T> {
  const Patch._();
}

/// An argument that was supplied, carrying [value].
///
/// A `Value(...)` pattern also matches [Clear], whose [value] is `null`.
///
/// Two `Value`s are equal when their [value]s are, whatever their type
/// arguments. `Clear()` therefore equals `Value(null)`, which is what the two
/// spellings already mean.
base class Value<T> extends Patch<T> {
  /// The supplied value.
  final T value;

  /// Creates a supplied argument carrying [value].
  const Value(this.value) : super._();

  @override
  bool operator ==(Object other) => other is Value && other.value == value;

  @override
  int get hashCode => Object.hash(Value, value);
}

/// An argument that was not supplied; the existing value should be kept.
///
/// All `Unchanged`s are equal, whatever their type arguments, and none is equal
/// to a [Value].
final class Unchanged<T> extends Patch<T> {
  /// Creates an omitted argument.
  const Unchanged() : super._();

  @override
  bool operator ==(Object other) => other is Unchanged;

  @override
  int get hashCode => (Unchanged).hashCode;
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
}

/// Folds a [Patch] against the value it is being applied to.
///
/// This is an extension rather than a method on [Patch] because [Clear] is a
/// `Value<Null>`, so an inherited method would take `current` as `Null` and
/// Dart's covariance check would throw whenever a populated field is cleared.
/// Extension methods are dispatched statically, so `current` is typed by the
/// call site instead.
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
