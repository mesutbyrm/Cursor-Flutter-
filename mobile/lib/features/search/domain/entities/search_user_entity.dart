import 'package:equatable/equatable.dart';

class SearchUserEntity extends Equatable {
  const SearchUserEntity({
    required this.id,
    required this.name,
    required this.username,
    this.image,
    this.bio,
  });

  final String id;
  final String name;
  final String username;
  final String? image;
  final String? bio;

  @override
  List<Object?> get props => [id, name, username, image, bio];
}
