class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String storageUrl;
  final int order;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.storageUrl,
    required this.order,
  });

  factory TrackModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TrackModel(
      id: id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      storageUrl: data['storageUrl'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}