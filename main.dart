import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Auth Status Enum
enum AuthStatus {
  initial,
  loading,
  error,
  login,
  signup,
}

// AuthState Class
class AuthState extends Equatable {
  const AuthState({required this.status, this.errorMessage = ''});

  final AuthStatus status;
  final String errorMessage;

  static AuthState initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({AuthStatus? status, String? errorMessage}) => AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object> get props => [status.name, errorMessage];
}

// AuthEvent Class (you may have this separately or inlined here)
abstract class AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String userName;

  SignUpEvent({required this.email, required this.password, required this.userName});
}

class LogInEvent extends AuthEvent {
  final String email;
  final String password;

  LogInEvent({required this.email, required this.password});
}

// AuthBloc Class
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthService service})
      : _service = service,
        super(AuthState.initial()) {
    on<SignUpEvent>(_onSignUpEvent);
    on<LogInEvent>(_onLogInEvent);
  }

  final AuthService _service;

  Future<void> _onSignUpEvent(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final signUpResponse = await _service.signUp(event.email, event.password, event.userName);
      late UserModel userModel;
      signUpResponse.fold(
        (error) => throw error.message,
        (user) => userModel = user,
      );

      final res = await _service.saveToFirestore(userModel.toMap());
      res.fold(
        (error) => throw error.message,
        (success) => emit(state.copyWith(status: AuthStatus.signup)),
      );
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogInEvent(LogInEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final signUpResponse = await _service.login(event.email, event.password);
      signUpResponse.fold(
        (error) => throw error.message,
        (userId) => emit(state.copyWith(status: AuthStatus.login)),
      );
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }
}

// Example Service and UserModel classes (you likely have these separately)
class AuthService {
  Future<Either<Error, UserModel>> signUp(String email, String password, String userName) {
    // Sign-up logic here
  }

  Future<Either<Error, Success>> saveToFirestore(Map<String, dynamic> userMap) {
    // Save user details to Firestore logic here
  }

  Future<Either<Error, String>> login(String email, String password) {
    // Login logic here
  }
}

class UserModel {
  String email;
  String userName;

  UserModel({required this.email, required this.userName});

  Map<String, dynamic> toMap() {
    // Convert user model to map for Firestore
  }
}

class Error {
  final String message;
  Error(this.message);
}

class Success {
  final String message;
  Success(this.message);
}
