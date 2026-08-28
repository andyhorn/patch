## 1.0.0

- Added `Patch<T>`, a sealed wrapper for `copyWith` arguments that tells an
  omitted argument apart from one supplied as `null`.
- Added the `Value<T>` and `Unchanged<T>` variants, which respectively replace a
  field and leave it alone.
- Added `Clear`, a `Value<Null>` naming the intent to null out a field. It
  satisfies `Patch<T?>` but not `Patch<T>`, so clearing a non-nullable field is a
  compile error, and a `Value(...)` pattern already matches it.
