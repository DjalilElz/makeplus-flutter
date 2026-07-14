import 'package:flutter_test/flutter_test.dart';

import 'package:makeplus/core/constants/user_roles.dart';
import 'package:makeplus/routes/app_router.dart';

/// Guards the role contract against the backend.
///
/// The canonical values below are what `UserEventAssignment.role` actually
/// stores (verified in the Django source). If the backend renames a role, these
/// tests fail here rather than silently dumping every user on the participant
/// home screen via `getRoleHomeRoute`'s fallback.
void main() {
  group('canonical backend role values', () {
    test('gestionnaire_des_salles is the room manager', () {
      expect(UserRoles.isRoomManager('gestionnaire_des_salles'), isTrue);
      expect(UserRoles.isBadgeController('gestionnaire_des_salles'), isFalse);
      expect(
        AppRouter.getRoleHomeRoute('gestionnaire_des_salles'),
        AppRouter.organizerRoomManagerHome,
      );
    });

    test('controlleur_des_badges is the badge controller', () {
      expect(UserRoles.isBadgeController('controlleur_des_badges'), isTrue);
      expect(UserRoles.isRoomManager('controlleur_des_badges'), isFalse);
      expect(
        AppRouter.getRoleHomeRoute('controlleur_des_badges'),
        AppRouter.organizerBadgeControllerHome,
      );
    });

    test('exposant is the exhibitor', () {
      expect(UserRoles.isExhibitor('exposant'), isTrue);
      expect(
        AppRouter.getRoleHomeRoute('exposant'),
        AppRouter.exposantHome,
      );
    });

    test('participant is the participant', () {
      expect(UserRoles.isParticipant('participant'), isTrue);
      expect(
        AppRouter.getRoleHomeRoute('participant'),
        AppRouter.participantHome,
      );
    });
  });

  group('role normalisation', () {
    test('is case- and separator-insensitive', () {
      expect(UserRoles.isRoomManager('GESTIONNAIRE-DES-SALLES'), isTrue);
      expect(UserRoles.isRoomManager('Gestionnaire Des Salles'), isTrue);
    });

    test('strips French accents', () {
      expect(UserRoles.isBadgeController('contrôleur_des_badges'), isTrue);
      expect(UserRoles.isBadgeController('controleur_des_badges'), isTrue);
    });

    test('roles are mutually exclusive', () {
      const roles = [
        'gestionnaire_des_salles',
        'controlleur_des_badges',
        'exposant',
        'participant',
      ];
      for (final role in roles) {
        final matches = [
          UserRoles.isRoomManager(role),
          UserRoles.isBadgeController(role),
          UserRoles.isExhibitor(role),
          UserRoles.isParticipant(role),
        ].where((m) => m).length;
        expect(matches, 1, reason: '"$role" should match exactly one role');
      }
    });
  });

  group('unknown roles', () {
    // The backend also has a `committee` role, which has no mobile UI. It must
    // not be mistaken for one of the four supported roles.
    test('committee matches no mobile role', () {
      expect(UserRoles.isRoomManager('committee'), isFalse);
      expect(UserRoles.isBadgeController('committee'), isFalse);
      expect(UserRoles.isExhibitor('committee'), isFalse);
      expect(UserRoles.isParticipant('committee'), isFalse);
    });

    test('getDisplayName echoes an unknown role rather than throwing', () {
      expect(UserRoles.getDisplayName('committee'), 'committee');
    });
  });
}
