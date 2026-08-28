// A console example prints by design.
// ignore_for_file: avoid_print

import 'package:patch/patch.dart';

class UserProfile {
  UserProfile(this.name, this.nickname);

  final String name;
  final String? nickname;

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
  print('original:     $profile');

  // Omitting an argument defaults to `Unchanged()`: the field is left alone.
  print('untouched:    ${profile.copyWith()}');

  // `Value` supplies a replacement.
  final renamed = profile.copyWith(nickname: const Value('The Countess'));
  print('renamed:      $renamed');

  // `Clear` clears the field — the case a plain `copyWith` cannot express,
  // because `copyWith(nickname: null)` is indistinguishable from `copyWith()`.
  final cleared = profile.copyWith(nickname: const Clear());
  print('cleared:      $cleared');

  final both = profile.copyWith(
    name: const Value('Ada King'),
    nickname: const Clear(),
  );
  print('both changed: $both');

  // Non-nullable fields use the same API, and clearing one does not compile:
  //
  //   profile.copyWith(name: const Clear());
  //   ^ The argument type 'Clear' can't be assigned to 'Patch<String>'.
}
