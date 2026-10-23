abstract class ChatSessionRepository {
  Future<void> connect(String roomName, String code);

  Future<void> disconnect();
}
