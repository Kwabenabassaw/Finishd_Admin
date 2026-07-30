import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:finishd_admin/core/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseService extends Mock implements SupabaseService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<PostgrestList> {
  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) async {
    return await onValue([]);
  }
}

class MockUser extends Mock implements User {}

void main() {
  late AdminRepository repository;
  late MockSupabaseService mockService;
  late MockSupabaseClient mockClient;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockService = MockSupabaseService();
    mockClient = MockSupabaseClient();

    // Default setup for service returning client if needed
    // Use thenAnswer since SupabaseClient is not a Future but sometimes things get confusing
    when(() => mockService.client).thenAnswer((_) => mockClient);

    repository = AdminRepository(mockService);
  });

  group('AdminRepository', () {
    group('Dashboard', () {
      test('getDashboardStats calls getAdminDashboardStats', () async {
        when(() => mockService.getAdminDashboardStats())
            .thenAnswer((_) async => {'users': 100});

        final result = await repository.getDashboardStats();

        expect(result, {'users': 100});
        verify(() => mockService.getAdminDashboardStats()).called(1);
      });

      test('getDailyUserStats calls service', () async {
        when(() => mockService.getDailyUserStats(7))
            .thenAnswer((_) async => [{'date': '2023-01-01'}]);

        final result = await repository.getDailyUserStats(7);

        expect(result, [{'date': '2023-01-01'}]);
        verify(() => mockService.getDailyUserStats(7)).called(1);
      });

      test('getDailyVideoStats calls service', () async {
        when(() => mockService.getDailyVideoStats(7)).thenAnswer((_) async => []);
        await repository.getDailyVideoStats(7);
        verify(() => mockService.getDailyVideoStats(7)).called(1);
      });
    });

    group('Users', () {
      test('getUsers calls getAdminUsers', () async {
        when(() => mockService.getAdminUsers(page: 2, limit: 10, search: 'test'))
            .thenAnswer((_) async => []);

        await repository.getUsers(page: 2, limit: 10, search: 'test');

        verify(() => mockService.getAdminUsers(page: 2, limit: 10, search: 'test')).called(1);
      });

      test('banUser calls banUser', () async {
        when(() => mockService.banUser('user_123', 'spam'))
            .thenAnswer((_) async => {});

        await repository.banUser('user_123', 'spam');

        verify(() => mockService.banUser('user_123', 'spam')).called(1);
      });

      test('unbanUser calls unbanUser', () async {
        when(() => mockService.unbanUser('user_123'))
            .thenAnswer((_) async => {});

        await repository.unbanUser('user_123');

        verify(() => mockService.unbanUser('user_123')).called(1);
      });

      test('updateUserStatus calls updateUserStatus', () async {
        when(() => mockService.updateUserStatus('user_123', 'suspend', true))
            .thenAnswer((_) async => {});

        await repository.updateUserStatus('user_123', 'suspend', true);

        verify(() => mockService.updateUserStatus('user_123', 'suspend', true)).called(1);
      });

      test('deleteUser calls deleteUser', () async {
        when(() => mockService.deleteUser('user_123'))
            .thenAnswer((_) async => {});

        await repository.deleteUser('user_123');

        verify(() => mockService.deleteUser('user_123')).called(1);
      });
    });

    group('Creators', () {
      test('getApprovedCreators calls getApprovedCreators', () async {
        when(() => mockService.getApprovedCreators()).thenAnswer((_) async => []);
        await repository.getApprovedCreators();
        verify(() => mockService.getApprovedCreators()).called(1);
      });

      test('approveCreator calls approveCreatorApplication', () async {
        when(() => mockService.approveCreatorApplication('app_1')).thenAnswer((_) async => {});
        await repository.approveCreator('app_1');
        verify(() => mockService.approveCreatorApplication('app_1')).called(1);
      });

      test('rejectCreator calls rejectCreatorApplication', () async {
        when(() => mockService.rejectCreatorApplication('app_1', 'reason')).thenAnswer((_) async => {});
        await repository.rejectCreator('app_1', 'reason');
        verify(() => mockService.rejectCreatorApplication('app_1', 'reason')).called(1);
      });
    });

    group('Moderation', () {
      test('getReports calls getReports', () async {
        when(() => mockService.getReports(status: 'resolved')).thenAnswer((_) async => []);
        await repository.getReports(status: 'resolved');
        verify(() => mockService.getReports(status: 'resolved')).called(1);
      });

      test('resolveReport calls resolveReport', () async {
        when(() => mockService.resolveReport('rep_1', 'dismiss', 'notes')).thenAnswer((_) async => {});
        await repository.resolveReport('rep_1', 'dismiss', 'notes');
        verify(() => mockService.resolveReport('rep_1', 'dismiss', 'notes')).called(1);
      });

      test('warnUser calls warnUser', () async {
        when(() => mockService.warnUser('user_1', 'spam')).thenAnswer((_) async => {});
        await repository.warnUser('user_1', 'spam');
        verify(() => mockService.warnUser('user_1', 'spam')).called(1);
      });

      test('suspendUser calls suspendUser', () async {
        when(() => mockService.suspendUser('user_1', 'spam', 24)).thenAnswer((_) async => {});
        await repository.suspendUser('user_1', 'spam', 24);
        verify(() => mockService.suspendUser('user_1', 'spam', 24)).called(1);
      });
    });

    group('Communities - updateCommunityStatus', () {
      test('throws ArgumentError if communityId is not a valid int', () async {
        expect(
          () => repository.updateCommunityStatus('not-an-int', 'suspended'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('calls freezeCommunity when status is suspended', () async {
        when(() => mockService.freezeCommunity(123, 'Admin action'))
            .thenAnswer((_) async => {});

        await repository.updateCommunityStatus('123', 'suspended');

        verify(() => mockService.freezeCommunity(123, 'Admin action')).called(1);
      });

      test('updates communities table directly for non-suspended status', () async {
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final fakeFilterBuilder = FakePostgrestFilterBuilder();

        when(() => mockClient.from('communities')).thenAnswer((_) => mockQueryBuilder);
        // Using thenAnswer to return the fake filter builder to bypass mocktail's check
        // for thenReturn on types extending Future (PostgrestFilterBuilder implements Future)
        when(() => mockQueryBuilder.update(any())).thenAnswer((_) => fakeFilterBuilder);

        await repository.updateCommunityStatus('123', 'active');

        verify(() => mockClient.from('communities')).called(1);
        verify(() => mockQueryBuilder.update({'status': 'active'})).called(1);
      });
    });
  });
}
