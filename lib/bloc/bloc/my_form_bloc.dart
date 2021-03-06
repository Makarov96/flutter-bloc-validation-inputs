import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:validationinput/models/email.dart';
import 'package:validationinput/models/models.dart';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';

part 'my_form_event.dart';
part 'my_form_state.dart';

class MyFormBloc extends Bloc<MyFormEvent, MyFormState> {
  MyFormBloc() : super(const MyFormState());

  @override
  void onTransition(Transition<MyFormEvent, MyFormState> transition) {
    if (state.status.isSubmissionSuccess) {
      print('${state.email.value}  ${state.password.value}');
    }
    super.onTransition(transition);
  }

  @override
  Stream<Transition<MyFormEvent, MyFormState>> transformEvents(
    Stream<MyFormEvent> events,
    TransitionFunction<MyFormEvent, MyFormState> transitionFn,
  ) {
    final debounced = events
        .where((event) => event is! FormSubmitted)
        .debounceTime(const Duration(milliseconds: 300));
    return events
        .where((event) => event is FormSubmitted)
        .mergeWith([debounced]).switchMap(transitionFn);
  }

  @override
  Stream<MyFormState> mapEventToState(MyFormEvent event) async* {
    if (event is EmailChanged) {
      final email = Email.dirty(event.email);
      yield state.copyWith(
        email: email,
        status: Formz.validate([email, state.password]),
      );
    } else if (event is PasswordChanged) {
      final password = Password.dirty(event.password);
      yield state.copyWith(
        password: password,
        status: Formz.validate([state.email, password]),
      );
    } else if (event is FormSubmitted) {
      if (state.status.isValidated) {
        yield state.copyWith(status: FormzStatus.submissionInProgress);
        await Future<void>.delayed(const Duration(seconds: 1));
        yield state.copyWith(status: FormzStatus.submissionSuccess);
        yield state.copyWith(password: Password.pure(), email: Email.pure());
      }
    }
  }
}
