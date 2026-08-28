import 'package:patch/patch.dart';
import 'package:test/test.dart';

class _Person(final String name, final String? nickname);

extension on _Person {
  _Person copyWith({
    Patch<String> name = const Unchanged(),
    Patch<String?> nickname = const Unchanged(),
  }) => _Person(name.resolve(this.name), nickname.resolve(this.nickname));
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

    group('resolve', () {
      test('supplies the value of a $Value', () {
        expect(Value('Grace').resolve('Ada'), equals('Grace'));
      });

      test('gives back the current value for an $Unchanged', () {
        expect(const Unchanged<String>().resolve('Ada'), equals('Ada'));
      });

      test('supplies null for a $Value of null', () {
        expect(const Value<String?>(null).resolve('Ada'), isNull);
      });

      // `Clear` is a `Value<Null>`. An inherited method would take `current` as
      // `Null` and fail Dart's covariance check on a non-null current value, so
      // this is the case that pins `resolve` to being an extension.
      test('supplies null for a $Clear over a non-null current value', () {
        final Patch<String?> patch = const Clear();

        expect(patch.resolve('Ada'), isNull);
      });

      test('supplies null for a $Clear over a null current value', () {
        final Patch<String?> patch = const Clear();

        expect(patch.resolve(null), isNull);
      });

      test('resolves a non-nullable patch', () {
        final Patch<int> supplied = Value(2);
        final Patch<int> omitted = const Unchanged();

        expect(supplied.resolve(1), equals(2));
        expect(omitted.resolve(1), equals(1));
      });

      test('agrees with an equivalent hand-written switch', () {
        String? byHand(Patch<String?> patch, String? current) =>
            switch (patch) {
              Value(value: final v) => v,
              Unchanged() => current,
            };

        for (final Patch<String?> patch in [
          Value('Grace'),
          Value(null),
          const Unchanged(),
          const Clear(),
        ]) {
          expect(patch.resolve('Ada'), equals(byHand(patch, 'Ada')));
        }
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

    group('equality', () {
      test('equates separately constructed $Value of the same value', () {
        expect(Value('a'), equals(Value('a')));
        expect(Value('a').hashCode, equals(Value('a').hashCode));
      });

      test('separates $Value of differing values', () {
        expect(Value('a'), isNot(equals(Value('b'))));
      });

      test('ignores the type argument of a $Value', () {
        expect(Value<Object>('a'), equals(Value<String>('a')));
        expect(
          Value<Object>('a').hashCode,
          equals(Value<String>('a').hashCode),
        );
      });

      test('equates all $Unchanged', () {
        expect(const Unchanged<String>(), equals(const Unchanged<int>()));
        expect(
          const Unchanged<String>().hashCode,
          equals(const Unchanged<int>().hashCode),
        );
      });

      test('separates $Unchanged from $Value', () {
        expect(const Unchanged<String?>(), isNot(equals(Value<String?>(null))));
        expect(Value<String?>(null), isNot(equals(const Unchanged<String?>())));
      });

      // `Clear` is `Value(null)` under another name, so equality follows suit.
      test('equates $Clear with a $Value of null', () {
        expect(const Clear(), equals(Value<String?>(null)));
        expect(Value<String?>(null), equals(const Clear()));
        expect(
          const Clear().hashCode,
          equals(Value<String?>(null).hashCode),
        );
      });

      test('separates $Clear from $Unchanged', () {
        expect(const Clear(), isNot(equals(const Unchanged<String?>())));
      });

      test('works as a map key and a set member', () {
        final seen = {Value('a'), Value('a'), const Unchanged<String>()};

        expect(seen, hasLength(2));
        expect({Value('a'): 1}[Value('a')], equals(1));
      });
    });
  });
}
