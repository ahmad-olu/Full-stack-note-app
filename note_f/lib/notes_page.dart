import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:note_f/bloc/auth_bloc/auth_bloc.dart';
import 'package:note_f/bloc/bloc/note_bloc.dart';
import 'package:note_f/model/note.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NoteBloc>()..add(GetAllNote()),
      child: const NotesView(),
    );
  }
}

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
          textScaler: TextScaler.linear(1.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.outlined(
                onPressed: () {
                  GoRouter.of(context).push("/create_notes");
                },
                icon: const Icon(Icons.add)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.outlined(
                onPressed: () {
                  context.read<AuthBloc>().add(DeleteApiKey());
                },
                icon: const Icon(Icons.exit_to_app_outlined)),
          )
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(listener: (context, state) {
        if (state.status == AuthStatus.unAuth) {
          context.go('/reg');
        }
      }, child: BlocBuilder<NoteBloc, NoteState>(
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.notes.length,
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    GoRouter.of(context).push('/notes/${note.id}');
                  },
                  child: SizedBox(
                    height: 180,
                    child: Card(
                      color: Colors.primaries[
                              math.Random().nextInt(Colors.primaries.length)]
                          .withOpacity(0.2),
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(note.createdAt),
                            //const Text('Today, 8:00 PM'),
                            const Divider(endIndent: 32, color: Colors.black),
                            Text(
                              note.description,
                              overflow: TextOverflow.clip,
                              maxLines: 3,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                            Icons.text_fields_outlined)),
                                  ],
                                ),
                                IconButton(
                                    onPressed: () => context
                                        .read<NoteBloc>()
                                        .add(DeleteSingleNote(id: note.id)),
                                    icon: const Icon(Icons.delete_outline)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      )),
    );
  }
}

class ViewNotePage extends StatelessWidget {
  const ViewNotePage({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context) {
    //.add(GetSingleNote(id: note.id))
    return BlocProvider.value(
      value: context.read<NoteBloc>()..add(GetSingleNote(id: id!)),
      child: ViewNoteView(
        id: id,
      ),
    );
  }
}

class ViewNoteView extends StatelessWidget {
  const ViewNoteView({super.key, required this.id});
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NoteBloc, NoteState, Note?>(
      selector: (state) {
        return state.singleNote;
      },
      builder: (context, state) {
        if (state == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text('no Data available '),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(state.title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(15.0),
            child: MarkdownWidget(
              data: state.description,
              config: MarkdownConfig(configs: [
                const H1Config(
                    style: TextStyle(
                  fontSize: 34,
                )),
                LinkConfig(
                  style: const TextStyle(
                    color: Colors.red,
                    decoration: TextDecoration.underline,
                  ),
                  onTap: (url) {
                    ///TODO:on tap
                  },
                )
              ]),
            ),
          ),
        );
      },
    );
  }
}
