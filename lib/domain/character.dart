class Character {
  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.origin,
    required this.location,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String status;
  final String species;
  final String origin;
  final String location;
  final String imageUrl;
}
