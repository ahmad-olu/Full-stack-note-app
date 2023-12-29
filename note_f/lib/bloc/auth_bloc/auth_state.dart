part of 'auth_bloc.dart';

enum AuthStatus { auth, loading, unAuth }

@immutable
sealed class AuthState {
  final String? apiKey;
  final String? genApiKey;

  final AuthStatus status;

  const AuthState(
      {required this.apiKey, required this.status, required this.genApiKey});
}

final class IsAuthenticated extends AuthState {
  const IsAuthenticated({required super.apiKey})
      : super(status: AuthStatus.auth, genApiKey: null);
}

final class IsNotAuthenticated extends AuthState {
  const IsNotAuthenticated({required super.apiKey})
      : super(status: AuthStatus.unAuth, genApiKey: null);
}

final class GeneratedApiKey extends AuthState {
  const GeneratedApiKey({
    required super.genApiKey,
  }) : super(status: AuthStatus.unAuth, apiKey: null);
}

final class IsLoading extends AuthState {
  const IsLoading()
      : super(status: AuthStatus.loading, genApiKey: null, apiKey: null);
}
