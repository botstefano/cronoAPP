class User {
  final int? id;
  final String username;
  final String nombre;
  final String token;

  User({
    this.id,
    required this.username,
    required this.nombre,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      nombre: json['nombre'],
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nombre': nombre,
        'token': token,
      };
}
