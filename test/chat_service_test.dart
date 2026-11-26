import 'package:flutter_test/flutter_test.dart';
import 'package:sos_pet/services/chat_service.dart';

void main() {
  group('ChatService.conversationId', () {
    test('is independent of participant order', () {
      final firstId = ChatService.conversationId(
        petId: 'pet-1',
        currentUid: 'user-a',
        ownerUid: 'user-b',
      );
      final reversedId = ChatService.conversationId(
        petId: 'pet-1',
        currentUid: 'user-b',
        ownerUid: 'user-a',
      );

      expect(firstId, reversedId);
    });

    test('uses a distinct id for a different pet', () {
      final firstId = ChatService.conversationId(
        petId: 'pet-1',
        currentUid: 'user-a',
        ownerUid: 'user-b',
      );
      final secondId = ChatService.conversationId(
        petId: 'pet-2',
        currentUid: 'user-a',
        ownerUid: 'user-b',
      );

      expect(firstId, isNot(secondId));
    });

    test('returns a URL-safe document id without padding', () {
      final id = ChatService.conversationId(
        petId: 'pet/with spaces',
        currentUid: 'user-a',
        ownerUid: 'user-b',
      );

      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });
  });
}
