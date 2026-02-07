import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.serverError([String? message]) = ServerError;
  const factory Failure.networkError([String? message]) = NetworkError;
  const factory Failure.storageError([String? message]) = StorageError;
  const factory Failure.blockchainError([String? message]) = BlockchainError;
  const factory Failure.validationError([String? message]) = ValidationError;
  const factory Failure.unauthorized([String? message]) = Unauthorized;
  const factory Failure.notFound([String? message]) = NotFound;
  const factory Failure.unknown([String? message]) = Unknown;
}

extension FailureExtension on Failure {
  String get message => when(
        serverError: (msg) => msg ?? 'Server error occurred',
        networkError: (msg) => msg ?? 'Network connection failed',
        storageError: (msg) => msg ?? 'Storage operation failed',
        blockchainError: (msg) => msg ?? 'Blockchain transaction failed',
        validationError: (msg) => msg ?? 'Validation failed',
        unauthorized: (msg) => msg ?? 'Unauthorized access',
        notFound: (msg) => msg ?? 'Resource not found',
        unknown: (msg) => msg ?? 'An unknown error occurred',
      );
}
