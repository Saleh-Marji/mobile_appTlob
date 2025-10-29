class PrivateSpace {
  int id;
  String name;

  PrivateSpace({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'name': this.name,
      };

  factory PrivateSpace.fromJson(Map<String, dynamic> map) => PrivateSpace(
        id: map['id'],
        name: map['name'],
      );
}
