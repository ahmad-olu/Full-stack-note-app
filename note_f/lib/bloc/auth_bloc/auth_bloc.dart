import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:note_f/api/api.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Api api;
  AuthBloc({required this.api})
      : super(const IsNotAuthenticated(apiKey: null)) {
    on<CheckAuthStatus>((event, emit) async {
      AndroidOptions getAndroidOptions() => const AndroidOptions(
            encryptedSharedPreferences: true,
          );
      final storage = FlutterSecureStorage(aOptions: getAndroidOptions());
      String? value = await storage.read(key: "apiKey");

      log('apiKey:: $value');

      if (value == null || value.isEmpty) {
        return emit(IsNotAuthenticated(apiKey: value));
      }
      return emit(IsAuthenticated(apiKey: value));
    });

    on<UpdateApiKey>((event, emit) async {
      emit(const IsLoading());
      try {
        AndroidOptions getAndroidOptions() => const AndroidOptions(
              encryptedSharedPreferences: true,
            );
        final storage = FlutterSecureStorage(aOptions: getAndroidOptions());
        await storage.write(key: "apiKey", value: event.apiKey);
        emit(IsAuthenticated(apiKey: event.apiKey));
      } catch (e) {
        log(e.toString());
        throw Exception(e.toString());
      }
    });
    on<GenerateApiKey>((event, emit) async {
      try {
        final genApi =
            await api.generateApiKey(event.name, event.email, event.scope);

        emit(GeneratedApiKey(genApiKey: genApi.apiKey!));
      } catch (e) {
        log(e.toString());
        throw Exception(e.toString());
      }
    });
    on<ClearApiKey>((event, emit) async {
      try {
        AndroidOptions getAndroidOptions() => const AndroidOptions(
              encryptedSharedPreferences: true,
            );
        await FlutterSecureStorage(aOptions: getAndroidOptions())
            .delete(key: 'apiKey');
        return emit(const IsNotAuthenticated(apiKey: null));
      } catch (e) {
        log(e.toString());
        throw Exception(e.toString());
      }
    });
    on<DeleteApiKey>((event, emit) async {
      try {
        AndroidOptions getAndroidOptions() => const AndroidOptions(
              encryptedSharedPreferences: true,
            );
        await FlutterSecureStorage(aOptions: getAndroidOptions())
            .delete(key: 'apiKey');
        await api.deleteApiKey(state.apiKey!);
        return emit(const IsNotAuthenticated(apiKey: null));
      } catch (e) {
        log(e.toString());
        throw Exception(e.toString());
      }
    });
  }
}

//1703849674.5d9461ef-9a0e-47a3-9f81-a2d8f6b8bfa2