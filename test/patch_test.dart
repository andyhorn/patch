import 'package:patch/patch.dart';
import 'package:test/test.dart';

class _Person(final String name, final String? nickname);

extension on _Person {
  _Person copyWith({
    Patch<String> name = const Unchanged(),
    Patch<String?> nickname = const Unchanged(),
  }) => _Person(
    switch (name) {
      Value(value: final v) => v,
      Unchanged() => this.name,
    },
    switch (nickname) {
      Value(value: final v) => v,
      Unchanged() => this.nickname,
    },
  );
}

void main() {
  group(Patch, () {
    group('used as a copyWith argument', () {
      late _Person withNickname;
      late _Person withoutNickname;

      setUp(() {
        withNickname = _Person('Ada', 'The Countess');
        withoutNickname = _Person('Ada', null);
      });

      test('keeps the existing value when the argument is omitted', () {
        final result = withNickname.copyWith();

        expect(result.name, equals('Ada'));
        expect(result.nickname, equals('The Countess'));
      });

      test('keeps an existing null when the argument is omitted', () {
        expect(withoutNickname.copyWith().nickname, isNull);
      });

      test('keeps the existing value when passed an explicit $Unchanged', () {
        expect(
          withNickname.copyWith(nickname: const Unchanged()).nickname,
          equals('The Countess'),
        );
      });

      test('replaces the value when passed a $Value', () {
        expect(
          withNickname.copyWith(nickname: Value('Ada')).nickname,
          equals('Ada'),
        );
      });

      test('sets a previously null value when passed a $Value', () {
        expect(
          withoutNickname.copyWith(nickname: Value('Ada')).nickname,
          equals('Ada'),
        );
      });

      test('clears a non-null value when passed a $Clear', () {
        expect(withNickname.copyWith(nickname: const Clear()).nickname, isNull);
      });

      test('leaves an already null value null when passed a $Clear', () {
        expect(
          withoutNickname.copyWith(nickname: const Clear()).nickname,
          isNull,
        );
      });

      // The whole point of the type: `Value(null)` and `Clear()` mean the same
      // thing, but neither can be confused with an omitted argument.
      test('treats $Value of null the same as $Clear', () {
        expect(
          withNickname.copyWith(nickname: Value(null)).nickname,
          equals(withNickname.copyWith(nickname: const Clear()).nickname),
        );
        expect(withNickname.copyWith().nickname, isNotNull);
      });

      test('applies independently to each argument in a single call', () {
        final result = withNickname.copyWith(name: Value('Grace'));

        expect(result.name, equals('Grace'));
        expect(result.nickname, equals('The Countess'));
      });

      test('applies to every argument when all are supplied', () {
        final result = withNickname.copyWith(
          name: Value('Grace'),
          nickname: const Clear(),
        );

        expect(result.name, equals('Grace'));
        expect(result.nickname, isNull);
      });
    });

    group('as a sealed hierarchy', () {
      String describe(Patch<String?> patch) => switch (patch) {
        Value(value: final v) => 'value:$v',
        Unchanged() => 'unchanged',
      };

      test('switches exhaustively over $Value and $Unchanged', () {
        expect(describe(Value('a')), equals('value:a'));
        expect(describe(Value(null)), equals('value:null'));
        expect(describe(const Unchanged()), equals('unchanged'));
      });

      test('matches $Clear with a $Value pattern, binding null', () {
        expect(describe(const Clear()), equals('value:null'));
      });

      test('lets $Clear be singled out ahead of $Value', () {
        String describeClear(Patch<String?> patch) => switch (patch) {
          Clear() => 'clear',
          Value(value: final v) => 'value:$v',
          Unchanged() => 'unchanged',
        };

        expect(describeClear(const Clear()), equals('clear'));
        expect(describeClear(Value(null)), equals('value:null'));
      });

      test('exposes the wrapped value through $Value', () {
        expect(Value('a').value, equals('a'));
        expect(const Value<String?>(null).value, isNull);
        expect(const Clear().value, isNull);
      });

      test('canonicalizes identical const instances', () {
        expect(
          identical(const Unchanged<String>(), const Unchanged<String>()),
          isTrue,
        );
        expect(identical(const Clear(), const Clear()), isTrue);
      });
    });
  });
}
