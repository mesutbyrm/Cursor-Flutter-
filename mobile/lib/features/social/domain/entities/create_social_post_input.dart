/// Yeni sosyal paylaşım isteği.
class CreateSocialPostInput {
  const CreateSocialPostInput({
    required this.caption,
    this.imagePath,
    this.postType = 'image',
  });

  final String caption;
  final String? imagePath;
  final String postType;

  bool get hasMedia => imagePath != null && imagePath!.isNotEmpty;
}
