import 'package:patch/patch.dart';

class UserProfile(final String name, final String? nickname) {
  @override
  String toString() => 'UserProfile(name: $name, nickname: $nickname)';
}

extension on UserProfile {
  UserProfile copyWith({
    Patch<String> name = const Unchanged(),
    Patch<String?> nickname = const Unchanged(),
  }) => UserProfile(
    name.resolve(this.name),
    nickname.resolve(this.nickname),
  );
}

void main() {
  final profile = UserProfile('Ada Lovelace', 'Ada');
  print('original:     ${profile.toString()}');

  // Omitting an argument defaults to `Unchanged()`: the field is left alone.
  print('untouched:    ${profile.copyWith().toString()}');

  // `Value` supplies a replacement.
  print(
    'renamed:      ${profile.copyWith(nickname: Value('The Countess')).toString()}',
  );

  // `Clear` clears the field — the case a plain `copyWith` cannot express,
  // because `copyWith(nickname: null)` is indistinguishable from `copyWith()`.
  print(
    'cleared:      ${profile.copyWith(nickname: const Clear()).toString()}',
  );

  print(
    'both changed: ${profile.copyWith(name: Value('Ada King'), nickname: const Clear()).toString()}',
  );

  // Non-nullable fields use the same API, and clearing one does not compile:
  //
  //   profile.copyWith(name: const Clear());
  //   ^ The argument type 'Clear' can't be assigned to 'Patch<String>'.
}
