import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/error_reporter.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:redline/features/tasks/data/stint.dart';
import 'package:redline/features/tasks/data/stint_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository whose every write fails — to exercise the error path.
class _ThrowingStintRepository implements StintRepository {
  @override
  Stream<List<Stint>> watchStints() => const Stream.empty();
  @override
  Future<Stint> addStint(String title) => throw StateError('boom');
  @override
  Future<void> updateStint(Stint stint) => throw StateError('boom');
  @override
  Future<void> deleteStint(String id) => throw StateError('boom');
  @override
  Future<bool> incrementLaps(String id) => throw StateError('boom');
  @override
  Future<void> setDone(String id, bool isDone) => throw StateError('boom');
  @override
  Future<void> reorder(List<String> orderedIds) => throw StateError('boom');
}

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];
  final messages = <String?>[];
  @override
  void report(Object error, StackTrace stack, {String? reason, String? userMessage}) {
    errors.add(error);
    messages.add(userMessage);
  }
}

void main() {
  test('a failing stint write is caught + reported, never thrown', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reporter = _RecordingReporter();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      stintRepositoryProvider.overrideWithValue(_ThrowingStintRepository()),
      errorReporterProvider.overrideWithValue(reporter),
    ]);
    addTearDown(c.dispose);

    final actions = c.read(stintActionsProvider);

    // None of these should throw, even though every write fails.
    await actions.add('x');
    await actions.delete('any-id');

    expect(reporter.errors.length, 2);
    expect(reporter.errors.every((e) => e is StateError), isTrue);
    expect(reporter.messages, ["Couldn't add the stint.", "Couldn't delete the stint."]);
  });
}
