class LoginRequest {
  const LoginRequest({required this.staffId, required this.password});

  final String staffId;
  final String password;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'password': password,
  };
}