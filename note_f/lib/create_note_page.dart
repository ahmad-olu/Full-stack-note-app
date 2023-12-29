import 'dart:convert';
import 'dart:developer';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_f/bloc/auth_bloc/auth_bloc.dart';
import 'package:note_f/bloc/bloc/note_bloc.dart';
import 'package:note_f/editor/editor.dart';

class CreateNotePage extends StatefulWidget {
  const CreateNotePage({super.key});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final _formKey = GlobalKey<FormState>();
  late Future<String> _jsonString;
  EditorState? _editorState;
  late Editor _editor;

  @override
  void initState() {
    super.initState();
    _jsonString = Future.value(json.encode(emptyData));
    _editor = Editor(
      jsonString: _jsonString,
      onEditorStateChange: (editorState) {
        _editorState = editorState;
      },
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _editor = Editor(
      jsonString: _jsonString,
      onEditorStateChange: (editorState) {
        _editorState = editorState;
        _jsonString =
            Future.value(json.encode(_editorState!.document.toJson()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.of(context).size.height;
    return BlocConsumer<NoteBloc, NoteState>(
      listener: (context, state) {
        if (state.status == NoteStatus.formLoaded) {
          context.pop();
        }
      },
      builder: (context, state) {
        final isLoading =
            context.watch<NoteBloc>().state.status == NoteStatus.formLoading;
        return isLoading
            ? const Scaffold(
                body: Center(
                    child: Padding(
                padding: EdgeInsets.all(150.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                      textScaler: TextScaler.linear(1.8),
                    ),
                    SizedBox(height: 5),
                    LinearProgressIndicator()
                  ],
                ),
              )))
            : Scaffold(
                appBar: AppBar(
                  title: const Padding(
                    padding: EdgeInsets.only(left: 50),
                    child: Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  actions: [
                    IconButton.outlined(
                        onPressed: () async {
                          //to

                          // final toMarkdown =
                          //     documentToMarkdown(_editorState!.document);
                          // final toJson = json.encode(_editorState.document.toJson());

                          //from
                          // final fromMarkdown = json
                          //     .encode(markdownToDocument('Markdown Strings').toJson());
                          // final fromJson = json.encode('json String');
                          if (_formKey.currentState!.validate()) {
                            if (_editorState != null) {
                              final toMarkdown =
                                  documentToMarkdown(_editorState!.document);
                              context
                                  .read<NoteBloc>()
                                  .add(CreateDescription(toMarkdown));
                              context.read<NoteBloc>().add(PostNote());
                            } else {
                              await descriptionDialogue(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.send_outlined))
                  ],
                ),
                body: SizedBox(
                  height: pageHeight,
                  child: Column(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Your Title here',
                            ),
                            maxLines: 2,
                            minLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "This Title Field cannot be empty";
                              }
                              return null;
                            },
                            onChanged: (value) => context
                                .read<NoteBloc>()
                                .add(CreateTitle(value)),
                          ),
                        ),
                      )),
                      Expanded(
                        flex: 9,
                        child: _editor,
                      ),
                    ],
                  ),
                ));
      },
    );
  }
}

Future<void> descriptionDialogue(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        "Description cant be empty",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 5,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            child: const Text("close"),
          ),
        ),
      ],
    ),
  );
}

final emptyData = {
  "document": {
    "type": "page",
    "children": [
      {
        "type": "paragraph",
        "data": {"delta": []}
      },
      {
        "type": "heading",
        "data": {
          "delta": [
            {"insert": "Here is an example you can give it a try"}
          ],
          "level": 4,
          "align": "center"
        }
      },
      {
        "type": "todo_list",
        "data": {
          "delta": [
            {"insert": "Use the "},
            {
              "insert": " / ",
              "attributes": {"bg_color": "0x4d00BCF0", "code": true}
            },
            {"insert": " to insert blocks."}
          ],
          "checked": false
        }
      },
      {
        "type": "todo_list",
        "data": {
          "checked": false,
          "delta": [
            {"insert": "Select text to "},
            {
              "insert": "trigger the toolbar",
              "attributes": {"bg_color": "0x4de91e63"}
            },
            {"insert": " to "},
            {
              "insert": "format",
              "attributes": {
                "code": true,
                "bold": true,
                "underline": true,
                "italic": true,
                "font_color": "0xfff44336",
                "bg_color": "0x4d4caf50"
              }
            },
            {"insert": " your notes."}
          ]
        }
      },
      {
        "type": "paragraph",
        "data": {"delta": []}
      },
    ]
  }
};
