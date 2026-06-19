/// Yeni sosyal paylaşım isteği.
class CreateSocialPostInput {
  const CreateSocialPostInput({
    required this.caption,
    this.imagePath,
    this.videoPath,
    this.postType,
  });

  final String caption;
  final String? imagePath;
  final String? videoPath;
  final String? postType;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;
  bool get hasMedia => hasImage || hasVideo;

  String get resolvedType {
    if (postType != null && postType!.isNotEmpty) return postType!;
    if (hasVideo) return 'video';
    if (hasImage) return 'image';
    return 'text';
  }
}
