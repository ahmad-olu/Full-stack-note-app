import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:note_f/api/api.dart';
import 'package:note_f/bloc/auth_bloc/auth_bloc.dart';
import 'package:note_f/model/note.dart';

part 'note_event.dart';
part 'note_state.dart';

//emit(IsNotAuthenticated(apiKey: value))

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final Api api;
  final AuthBloc auth;
  NoteBloc({required this.api, required this.auth})
      : super(NoteState.initial()) {
    on<CreateTitle>((event, emit) {
      emit(state.copyWith(title: event.titleStr));
    });
    on<CreateDescription>((event, emit) {
      emit(state.copyWith(description: event.descriptionStr));
    });
    on<PostNote>((event, emit) async {
      emit(state.copyWith(status: NoteStatus.formLoading));
      log('got here 1');
      try {
        final note = Note(
            id: '',
            uid: '',
            createdAt: '',
            title: state.title,
            description: state.description);
        final res = await api.postNote(auth.state.apiKey!, note);
        emit(state.copyWith(
            notes: [...state.notes, res], status: NoteStatus.formLoaded));
        log('got here 2');
      } catch (e) {
        emit(state.copyWith(
            status: NoteStatus.formFailure, errorMessage: e.toString()));
        log(e.toString());

        throw Exception(e.toString());
      }
    });
    on<GetAllNote>((event, emit) async {
      emit(state.copyWith(status: NoteStatus.loading));
      try {
        final res = await api.getAllNotes(auth.state.apiKey!);

        emit(state.copyWith(notes: res, status: NoteStatus.loaded));
      } on NoApiKey catch (e) {
        emit(state.copyWith(
            status: NoteStatus.formFailure, errorMessage: e.errorMessage));
        if (e.errorMessage == 'Unable to get api key') {
          auth.add(ClearApiKey());
        }
      } catch (e) {
        emit(state.copyWith(
            status: NoteStatus.failure, errorMessage: e.toString()));
        log(e.toString());
        throw Exception(e.toString());
      }
    });
    on<GetSingleNote>((event, emit) async {
      emit(state.copyWith(status: NoteStatus.loading));
      try {
        // final res = await api.getNote(auth.state.apiKey!, event.id);
        // emit(state.copyWith(singleNote: res));

        final note = state.notes.where((notes) => notes.id == event.id).first;
        emit(state.copyWith(singleNote: note, status: NoteStatus.loaded));
      } catch (e) {
        emit(state.copyWith(
            status: NoteStatus.failure, errorMessage: e.toString()));
        log(e.toString());
        throw Exception(e.toString());
      }
    });
    on<DeleteSingleNote>((event, emit) async {
      try {
        await api.deleteNote(auth.state.apiKey!, event.id);
        final notes =
            state.notes.where((notes) => notes.id != event.id).toList();
        emit(state.copyWith(notes: notes));
      } catch (e) {
        log(e.toString());
        throw Exception(e.toString());
      }
    });
  }
}
