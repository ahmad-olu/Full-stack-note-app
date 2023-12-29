part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class CheckAuthStatus extends AuthEvent {
  CheckAuthStatus();
}

final class UpdateApiKey extends AuthEvent {
  final String apiKey;

  UpdateApiKey({required this.apiKey});
}

final class GenerateApiKey extends AuthEvent {
  final String name;
  final String email;
  final List<String> scope;
  GenerateApiKey(this.name, this.email, this.scope);
}

final class ClearApiKey extends AuthEvent {
  ClearApiKey();
}

final class DeleteApiKey extends AuthEvent {
  DeleteApiKey();
}
