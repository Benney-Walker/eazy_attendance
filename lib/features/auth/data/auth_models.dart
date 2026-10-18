class LoginRequest {
  const LoginRequest({required this.staffId, required this.password});

  final String staffId;
  final String password;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'password': password,
  };
}

class LoginResponse {
  const LoginResponse({
    required this.authToken,
    required this.refreshToken,
    required this.staffName,
    required this.staffId,
    required this.institutionName,
    this.roles = const [],
  });

  final String authToken;
  final String refreshToken;
  final String staffName;
  final String staffId;
  final String institutionName;
  final List<String> roles;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    return LoginResponse(
      authToken: (json['authToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      staffName: (json['staffName'] ?? '').toString(),
      staffId: (json['staffId'] ?? '').toString(),
      institutionName: (json['institutionName'] ?? '').toString(),
      roles: rawRoles is List
          ? rawRoles.map((e) => e.toString()).toList()
          : const [],
    );
  }
}