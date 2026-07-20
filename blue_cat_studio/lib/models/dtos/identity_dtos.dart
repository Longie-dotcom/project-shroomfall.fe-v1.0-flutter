class LoginDTO {
  final String email;
  final String password;

  LoginDTO({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class RefreshTokenDTO {
  final String refreshToken;

  RefreshTokenDTO({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
    'refreshToken': refreshToken,
  };
}

class TokenDTO {
  final String accessToken;
  final String refreshToken;

  TokenDTO({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenDTO.fromJson(Map<String, dynamic> json) {
    return TokenDTO(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}