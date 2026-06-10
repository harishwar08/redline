import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/auth/data/profile_bootstrap.dart';

/// §4 — account-bootstrap profile write. Verifies, against an in-memory Firestore,
/// that the doc written on sign-up / first Google sign-in satisfies the
/// `validProfile()` rule (name + createdAt required), uses set-with-merge, only
/// stamps createdAt on the first write, and writes nothing the rules reject.
void main() {
  Map<String, dynamic> profileOf(Map<String, dynamic> doc) =>
      Map<String, dynamic>.from(doc['profile'] as Map);

  Future<Map<String, dynamic>> readUser(FakeFirebaseFirestore db, String uid) async =>
      (await db.collection('users').doc(uid).get()).data()!;

  group('writeSignUpProfile', () {
    test('first write creates a rule-valid profile: name + email + server createdAt',
        () async {
      final db = FakeFirebaseFirestore();
      await ProfileBootstrap(db).writeSignUpProfile(
        uid: 'u1',
        name: 'Ada Lovelace',
        email: 'ada@redline.app',
      );

      final profile = profileOf(await readUser(db, 'u1'));
      expect(profile['name'], 'Ada Lovelace'); // validProfile: name is string
      expect(profile['email'], 'ada@redline.app');
      expect(profile['createdAt'], isA<Timestamp>()); // validProfile: createdAt is timestamp
      // Only allowed keys — nothing validProfile()/validUserDoc() would reject.
      expect(profile.keys.toSet(), {'name', 'email', 'createdAt'});
    });

    test('merges into an existing guest profile: preserves createdAt + siblings',
        () async {
      final db = FakeFirebaseFirestore();
      final original = Timestamp.fromDate(DateTime.utc(2020, 1, 1));
      // A linked guest already has a profile (with its own createdAt + extras)
      // plus a sibling settings map on the same doc.
      await db.collection('users').doc('u1').set({
        'profile': {'name': 'Privateer', 'createdAt': original, 'age': 30, 'sex': 'female'},
        'settings': {'soundsEnabled': true},
      });

      await ProfileBootstrap(db).writeSignUpProfile(
        uid: 'u1',
        name: 'Ada Lovelace',
        email: 'ada@redline.app',
      );

      final doc = await readUser(db, 'u1');
      final profile = profileOf(doc);
      expect(profile['name'], 'Ada Lovelace'); // updated from the form
      expect(profile['email'], 'ada@redline.app'); // added
      expect(profile['createdAt'], original); // NOT re-stamped — guest's original kept
      expect(profile['age'], 30); // deep-merge preserved the siblings
      expect(profile['sex'], 'female');
      expect(doc['settings'], isNotNull); // other top-level maps untouched
    });
  });

  group('ensureProfileIfAbsent', () {
    test('writes a rule-valid profile when none exists', () async {
      final db = FakeFirebaseFirestore();
      await ProfileBootstrap(db).ensureProfileIfAbsent(
        uid: 'g1',
        name: 'Google User',
        email: 'g@redline.app',
      );

      final profile = profileOf(await readUser(db, 'g1'));
      expect(profile['name'], 'Google User');
      expect(profile['email'], 'g@redline.app');
      expect(profile['createdAt'], isA<Timestamp>());
      expect(profile.keys.toSet(), {'name', 'email', 'createdAt'});
    });

    test('does NOT overwrite a returning user’s existing profile', () async {
      final db = FakeFirebaseFirestore();
      final original = Timestamp.fromDate(DateTime.utc(2021, 6, 1));
      await db.collection('users').doc('g1').set({
        'profile': {'name': 'Edited Name', 'createdAt': original},
      });

      await ProfileBootstrap(db).ensureProfileIfAbsent(
        uid: 'g1',
        name: 'Google Display Name',
        email: 'g@redline.app',
      );

      final profile = profileOf(await readUser(db, 'g1'));
      expect(profile['name'], 'Edited Name'); // unchanged
      expect(profile['createdAt'], original);
      expect(profile.containsKey('email'), isFalse); // nothing added
    });

    test('omits email when null', () async {
      final db = FakeFirebaseFirestore();
      await ProfileBootstrap(db).ensureProfileIfAbsent(uid: 'g2', name: 'No Email', email: null);

      final profile = profileOf(await readUser(db, 'g2'));
      expect(profile.containsKey('email'), isFalse);
      expect(profile.keys.toSet(), {'name', 'createdAt'});
    });
  });
}
