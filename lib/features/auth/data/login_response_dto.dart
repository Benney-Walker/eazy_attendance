class LoginResponse {
  const LoginResponse({
    required this.authToken,
    required this.staffName,
    required this.staffId,
  });

  final String authToken;
  final String staffName;
  final String staffId;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      authToken: (json['authToken'] ?? '').toString(),
      staffName: (json['staffName'] ?? '').toString(),
      staffId: (json['staffId'] ?? '').toString(),
    );
  }
}