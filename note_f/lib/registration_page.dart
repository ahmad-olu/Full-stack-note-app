import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_f/bloc/auth_bloc/auth_bloc.dart';

class RegPage extends StatelessWidget {
  const RegPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: context.read<AuthBloc>(),
      child: const RegView(),
    );
  }
}

class RegView extends StatefulWidget {
  const RegView({super.key});

  @override
  State<RegView> createState() => _RegViewState();
}

class _RegViewState extends State<RegView> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  bool _isSmallCard = true;
  final _scopeList = [
    ScopeCheckBoxState(title: "notes.read", value: true),
    ScopeCheckBoxState(title: "notes.create"),
    ScopeCheckBoxState(title: "notes.update"),
    ScopeCheckBoxState(title: "notes.delete"),
  ];
  final apiKeyController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    apiKeyController.dispose();
    emailController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.auth) {
          context.go('/notes');
        }
        if (state.genApiKey != null) {
          await resultDialogue(context, state.genApiKey!);
        }
      },
      builder: (context, state) {
        if (state.status == AuthStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final apiKey = context.watch<AuthBloc>().state.genApiKey;
        if (apiKey != null) {
          apiKeyController.text = apiKey;
        }

        return Center(
          child: SingleChildScrollView(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: _isSmallCard ? Curves.easeInOutBack : Curves.easeInOut,
              height: _isSmallCard ? 150 : 500,
              width: 500,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSmallCard)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Form(
                                  key: _formKey1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: RegTextFormField(
                                      controller: apiKeyController,
                                      helperText: "Api key ⬆️ ",
                                      onChanged: (p0) {},
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey1.currentState!.validate()) {
                                    context.read<AuthBloc>().add(UpdateApiKey(
                                        apiKey: apiKeyController.text));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    fixedSize: const Size.fromHeight(50)),
                                child: const Text('🏃',
                                    textScaler: TextScaler.linear(1.8)),
                              )
                            ],
                          ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSmallCard = !_isSmallCard;
                            });
                          },
                          child: Text(
                            _isSmallCard
                                ? "Don't Have an api key ?. Tap This"
                                : "Already have an api key ?. Tap This",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textScaler: const TextScaler.linear(1.1),
                          ),
                        ),
                        if (!_isSmallCard)
                          Form(
                            key: _formKey2,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                RegTextFormField(
                                  controller: emailController,
                                  helperText: "Email ⬆️",
                                  hintText: "mike@email.com",
                                  onChanged: (p0) {},
                                ),
                                const SizedBox(height: 12),
                                RegTextFormField(
                                  controller: nameController,
                                  helperText: "Name ⬆️",
                                  hintText: "My first api key",
                                  onChanged: (p0) {},
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Choose Scope ⬇️",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                  textScaler: TextScaler.linear(1.1),
                                ),
                                //userCheckedScopeList
                                //_scopeList
                                SizedBox(
                                  height: 170,
                                  child: ListView(
                                      children: _scopeList
                                          .map((box) =>
                                              CheckboxListTile.adaptive(
                                                value: box.value,
                                                onChanged: (value) {
                                                  setState(() {
                                                    box.value = value!;
                                                  });
                                                },
                                                title: Text(box.title),
                                              ))
                                          .toList()),
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey2.currentState!.validate()) {
                                        final scopeValue = _scopeList
                                            .where((element) =>
                                                element.value == true)
                                            .map((e) => e.title)
                                            .toList();
                                        context
                                            .read<AuthBloc>()
                                            .add(GenerateApiKey(
                                              nameController.text,
                                              emailController.text,
                                              scopeValue,
                                            ));
                                      }

                                      //
                                      // final data = ClipboardData(
                                      //     text: apiKeyController.text);
                                      // Clipboard.setData(data);
                                      //apiKeyController.text = "aaaaaaaaaaaaaaaaa";
                                    },
                                    child: const Text('Send'))
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }
}

class ScopeCheckBoxState {
  final String title;
  bool value;

  ScopeCheckBoxState({required this.title, this.value = false});
}

class RegTextFormField extends StatelessWidget {
  const RegTextFormField({
    super.key,
    this.helperText,
    this.onChanged,
    this.hintText,
    this.controller,
  });
  final String? helperText;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hintText,
          helperText: helperText,
          helperStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 5,
            fontSize: 15,
          ),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'the field `$helperText` cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}

Future<void> resultDialogue(BuildContext context, String apiKey) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        "Create New Api Key",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 5,
        ),
      ),
      content: SizedBox(
        height: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Api key created and it will be displayed only now.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 40,
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      apiKey,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        final data = ClipboardData(text: apiKey);
                        Clipboard.setData(data);
                      },
                      icon: const Icon(Icons.copy))
                ],
              ),
            ),
            const Text(
              "Please store it somewhere safe because as soon as you navigate away from this page, we will not be able to retrieve or restore this generated token.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            )
          ],
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
