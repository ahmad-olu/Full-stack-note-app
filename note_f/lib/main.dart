import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_f/api/api.dart';
import 'package:note_f/bloc/auth_bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_f/bloc/bloc/note_bloc.dart';
import 'package:note_f/create_note_page.dart';
import 'package:note_f/notes_page.dart';
import 'package:note_f/registration_page.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/reg',
      builder: (context, state) => const RegPage(),
    ),
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: '/create_notes',
      builder: (context, state) => const CreateNotePage(),
    ),
    GoRoute(
      path: '/notes/:notesId',
      builder: (context, state) =>
          ViewNotePage(id: state.pathParameters['notesId']),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => Api(),
      child: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (context) => AuthBloc(api: context.read<Api>())
                  ..add(
                    CheckAuthStatus(),
                  )
                //  ..add(ClearApiKey()),
                ),
            BlocProvider(
              create: (context) => NoteBloc(
                  api: RepositoryProvider.of<Api>(context),
                  auth: BlocProvider.of<AuthBloc>(context)),
              child: const NotesView(),
            )
          ],
          child: MaterialApp.router(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerConfig: _router,
          )),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unAuth) {
          context.go('/reg');
        } else {
          context.go('/notes');
        }
      },
      child: const Scaffold(
        body: Center(
            child: Padding(
          padding: EdgeInsets.all(150.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Navigating...',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                textScaler: TextScaler.linear(1.8),
              ),
              SizedBox(height: 5),
              LinearProgressIndicator()
            ],
          ),
        )),
      ),
    );
  }
}
