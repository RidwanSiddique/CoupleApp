// lib/features/chat/domain/chat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/crypto/crypto_providers.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../data/chat_repository.dart';
import '../data/chat_store.dart';
import 'chat_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(supabaseClientProvider));
});

final chatStoreProvider = Provider<ChatStore>((ref) {
  return ChatStore(ref.watch(signalDbProvider));
});

/// Null until signed in + paired + this device is registered.
///
/// `signalSessionServiceProvider` is itself a `FutureProvider<
/// SignalSessionService?>` (null when signed out or unregistered) — awaiting
/// it here folds that same "not ready" state into `chatServiceProvider`
/// instead of duplicating the registration check.
final chatServiceProvider = FutureProvider<ChatService?>((ref) async {
  final session = await ref.watch(signalSessionServiceProvider.future);
  if (session == null) return null;

  final authSession = ref.watch(authSessionProvider).asData?.value;
  final couple = ref.watch(currentCoupleProvider).asData?.value;
  if (authSession == null || couple == null) return null;
  final selfId = authSession.user.id;

  final deviceNum = await ref.read(keyVaultProvider).readDeviceNum();
  if (deviceNum == null) return null; // not registered yet

  return ChatService(
    session: session,
    repo: ref.read(chatRepositoryProvider),
    store: ref.read(chatStoreProvider),
    selfUserId: selfId,
    spouseUserId: couple.spouseOf(selfId),
    selfDeviceNum: deviceNum,
  );
});

final conversationMessagesProvider =
    StreamProvider<List<ChatMessageRow>>((ref) {
  return ref.watch(chatStoreProvider).watchConversation();
});

/// Subscribes to the inbox stream and feeds each row through
/// [ChatService.handleInboxRow]. No-op until `chatServiceProvider` resolves
/// to a real service; cancels its subscription on dispose.
final inboxPumpProvider = Provider<void>((ref) {
  final svc = ref.watch(chatServiceProvider).asData?.value;
  final authSession = ref.watch(authSessionProvider).asData?.value;
  if (svc == null || authSession == null) return;
  final sub = ref
      .read(chatRepositoryProvider)
      .watchInbox(authSession.user.id)
      .listen((rows) async {
    for (final r in rows) {
      await svc.handleInboxRow(r);
    }
  });
  ref.onDispose(sub.cancel);
});
