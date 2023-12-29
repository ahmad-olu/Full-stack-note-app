part of 'note_bloc.dart';

enum NoteStatus {
  initial,

  loading,
  loaded,
  failure,
  formLoading,
  formLoaded,
  formFailure,
}

@immutable
class NoteState {
  final String title;
  final String description;
  final NoteStatus status;
  final List<Note> notes;
  final Note? singleNote;
  final String? errorMessage;

  const NoteState({
    required this.title,
    required this.description,
    required this.status,
    required this.notes,
    required this.singleNote,
    required this.errorMessage,
  });

  factory NoteState.initial() => const NoteState(
        status: NoteStatus.initial,
        notes: [],
        singleNote: null,
        errorMessage: null,
        description: '',
        title: '',
      );

  NoteState copyWith({
    String? title,
    String? description,
    NoteStatus? status,
    List<Note>? notes,
    Note? singleNote,
    String? errorMessage,
  }) {
    return NoteState(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      singleNote: singleNote ?? this.singleNote,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'NoteState(status: $status, notes: $notes, singleNote: $singleNote, errorMessage: $errorMessage)';
  }
}
