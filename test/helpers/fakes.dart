import 'package:cofre/core/security/key_derivation.dart';
import 'package:cofre/core/security/key_value_store.dart';
import 'package:cofre/core/security/password_cipher.dart';
import 'package:cofre/core/security/password_hasher.dart';
import 'package:cofre/core/services/clipboard_service.dart';
import 'package:cofre/core/services/file_transfer_service.dart';
import 'package:cofre/features/lock/data/secure_master_key_repository.dart';
import 'package:cofre/features/lock/domain/biometric_authenticator.dart';

/// Armazenamento em memória.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Armazenamento que falha ao escrever.
class FailingWriteStore extends InMemoryKeyValueStore {
  FailingWriteStore([super.initial]);

  @override
  Future<void> write(String key, String value) async => throw Exception('disk full');
}

/// Biometria com resultado fixo.
class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({this.result = true, this.failure});

  bool result;
  BiometricFailure? failure;
  int calls = 0;

  @override
  Future<bool> authenticate({required String reason}) async {
    calls++;
    if (failure != null) throw failure!;
    return result;
  }
}

/// Área de transferência em memória, para montar um [ClipboardService] real nos testes.
class FakeClipboard {
  String? content;
  bool lastWriteWasSensitive = false;

  /// Simula o Android bloqueando a leitura com o app em segundo plano.
  bool canRead = true;

  Future<void> write(String text, {required bool sensitive}) async {
    content = text;
    lastWriteWasSensitive = sensitive;
  }

  Future<String?> read() async => canRead ? (content ?? '') : null;

  ClipboardService service({Duration clearAfter = const Duration(seconds: 30)}) =>
      ClipboardService(clearAfter: clearAfter, write: write, read: read);
}

/// Seleção de arquivos em memória.
class FakeFileTransferService implements FileTransferService {
  String? savedContent;
  String? fileToPick;

  @override
  Future<bool> saveText({required String fileName, required String mimeType, required String content}) async {
    savedContent = content;
    return true;
  }

  @override
  Future<String?> pickText() async => fileToPick;
}

/// Derivação com poucas iterações e sem isolate, para os testes serem rápidos.
const fastKeyDerivation = KeyDerivation(iterations: 1000, runInIsolate: false);

PasswordCipher fastCipher() => PasswordCipher(keyDerivation: fastKeyDerivation);

/// Chave mestre já cadastrada no app de teste.
const testMasterKey = 'chave-mestre-1';

/// Repositório de chave mestre real sobre armazenamento em memória.
SecureMasterKeyRepository masterKeyRepository(KeyValueStore store) =>
    SecureMasterKeyRepository(store, const PasswordHasher(keyDerivation: fastKeyDerivation));
