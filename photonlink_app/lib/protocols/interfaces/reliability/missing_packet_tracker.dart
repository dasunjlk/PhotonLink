/// Tracks missing and duplicate packets during optical receive.
abstract interface class MissingPacketTracker {
  void onPacketReceived(int packetId, {required bool isNew});
  Set<int> get missingPacketIds;
  Set<int> get receivedPacketIds;
  int get duplicatesIgnored;
  int get totalExpected;
  void setTotalExpected(int total);
  void reset();
}
