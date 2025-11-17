class User {
  final String id;
  final String name;
  final String telephone;
  final String role;
  final int? age;
  final String? email;
  final String? address;
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.telephone,
    required this.role,
    this.age,
    this.email,
    this.address,
    this.profileImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id']).toString(),
      name: (json['name'] ?? '').toString(),
      telephone: (json['telephone'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      age: json['age'],
      email: json['email'],
      address: json['address'],
      profileImage: json['profileImage'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'telephone': telephone,
      'role': role,
      'age': age,
      'email': email,
      'address': address,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? telephone,
    String? role,
    int? age,
    String? email,
    String? address,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      age: age ?? this.age,
      email: email ?? this.email,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
