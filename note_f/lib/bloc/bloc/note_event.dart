part of 'note_bloc.dart';

@immutable
sealed class NoteEvent {}

final class CreateTitle extends NoteEvent {
  final String titleStr;

  CreateTitle(this.titleStr);
}

final class CreateDescription extends NoteEvent {
  final String descriptionStr;

  CreateDescription(this.descriptionStr);
}

final class PostNote extends NoteEvent {
  PostNote();
}

final class GetAllNote extends NoteEvent {
  GetAllNote();
}

final class GetSingleNote extends NoteEvent {
  final String id;

  GetSingleNote({required this.id});
}

final class DeleteSingleNote extends NoteEvent {
  final String id;

  DeleteSingleNote({required this.id});
}
