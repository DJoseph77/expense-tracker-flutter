import 'user_response.dart';

class AuthResponse {
  final String token;
  final String tokenType;
  final UserResponse user;

  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'tokenType': tokenType, 'user': user.toJson()};
  }
}
