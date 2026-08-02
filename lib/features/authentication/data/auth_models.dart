/// Request body for `POST /auth/v1/staff-login` — keys must match the backend
/// exactly: `{ staffId, password }` (see the website's LoginPage).
class LoginRequest {
  const LoginRequest({required this.staffId, required this.password});

  final String staffId;
  final String password;

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'password': password,
      };
}

/// Successful login response. The backend returns `authToken`, `staffName`,
/// and `staffId` (see the website's `saveAuth(data.authToken, data.staffName,
/// data.staffId)`).
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
