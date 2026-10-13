import 'package:cofre/core/security/key_derivation.dart';
import 'package:cofre/core/security/key_value_store.dart';
import 'package:cofre/core/security/password_cipher.dart';
import 'package:cofre/core/security/vault_key.dart';
import 'package:cofre/core/services/clipboard_service.dart';
import 'package:cofre/core/services/device_auth_service.dart';
import 'package:cofre/core/services/device_clock.dart';
import 'package:cofre/core/services/file_transfer_service.dart';
import 'package:cofre/core/storage/blob_store.dart';
import 'package:cofre/features/lock/data/secure_vault_key_repository.dart';
import 'package:cofre/features/lock/domain/biometric_key_store.dart';
import 'package:cofre/features/vault/data/repositories/encrypted_file_entry_repository.dart';
import 'package:cofre/features/vault/domain/entities/entry.dart';

/// Armazenamento chave/valor em memória.
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

/// Simula o Keystore com erro: toda operação falha enquanto [isFailing].
class FailingKeyValueStore implements KeyValueStore {
  FailingKeyValueStore(this._inner);

  final KeyValueStore _inner;
  bool isFailing = true;

  @override
  Future<String?> read(String key) async {
    _throwIfFailing();
    return _inner.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    _throwIfFailing();
    await _inner.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    _throwIfFailing();
    await _inner.delete(key);
  }

  void _throwIfFailing() {
    if (isFailing) throw Exception('keystore');
  }
}

/// Arquivos em memória, com a mesma semântica de backup do [FileBlobStore].
class InMemoryBlobStore implements BlobStore {
  final Map<String, List<int>> files = {};

  /// Faz a próxima gravação falhar (simula disco cheio).
  bool failWrites = false;

  @override
  Future<List<int>?> read(String name) async => files[name];

  @override
  Future<void> writeAtomic(String name, List<int> bytes, {String? backupName}) async {
    if (failWrites) throw Exception('disk full');
    final current = files[name];
    if (backupName != null && current != null) files[backupName] = current;
    files[name] = List.of(bytes);
  }

  @override
  Future<void> delete(String name) async => files.remove(name);
}

/// Digital simulada: "cifra" guardando uma cópia e permite injetar falhas.
class FakeBiometricKeyStore implements BiometricKeyStore {
  BiometricAvailability availabilityResult = BiometricAvailability.available;

  /// Próxima operação falha com este motivo (e volta a funcionar depois).
  BiometricKeyFailureReason? nextFailure;
  bool hasHardwareKey = false;
  int prompts = 0;

  @override
  Future<BiometricAvailability> availability() async => availabilityResult;

  @override
  Future<BiometricWrappedKey> wrap(List<int> secret, BiometricPromptTexts texts) async {
    _prompt();
    hasHardwareKey = true;
    return BiometricWrappedKey(iv: const [1, 2, 3], cipherText: List.of(secret));
  }

  @override
  Future<List<int>> unwrap(BiometricWrappedKey wrapped, BiometricPromptTexts texts) async {
    _prompt();
    if (!hasHardwareKey) throw const BiometricKeyFailure(BiometricKeyFailureReason.missing);
    return List.of(wrapped.cipherText);
  }

  @override
  Future<void> delete() async => hasHardwareKey = false;

  void _prompt() {
    prompts++;
    final failure = nextFailure;
    if (failure == null) return;
    nextFailure = null;
    throw BiometricKeyFailure(failure);
  }
}

/// Relógio monotônico simulado: anda junto com [clock]. Trocar [bootId] simula reiniciar o aparelho.
class FakeDeviceClock implements DeviceClock {
  FakeDeviceClock(this._clock, {this.bootId = 1});

  static final _origin = DateTime(2000);

  final DateTime Function() _clock;
  int bootId;

  @override
  Future<void> sync() async {}

  @override
  DeviceInstant now() => DeviceInstant(bootId: bootId, sinceBoot: _clock().difference(_origin));
}

/// Bloqueio de tela do aparelho simulado.
class FakeDeviceAuthService implements DeviceAuthService {
  DeviceAuthResult result = DeviceAuthResult.authenticated;
  int prompts = 0;

  @override
  Future<DeviceAuthResult> confirm({required String title, required String subtitle}) async {
    prompts++;
    return result;
  }
}

/// Área de transferência em memória, para montar um [ClipboardService] real nos testes.
class FakeClipboard {
  String? content;
  bool lastWriteWasSensitive = false;

  /// Simula o Android bloqueando a leitura com o app em segundo plano.
  bool canRead = true;

  /// Simula o canal nativo do Android, que agenda a limpeza por conta própria.
  bool platformClears = false;

  /// Prazo pedido ao canal nativo na última cópia sensível.
  Duration? platformClearAfter;

  Future<bool> writeSensitive(String text, Duration clearAfter) async {
    content = text;
    lastWriteWasSensitive = true;
    if (!platformClears) return false;
    platformClearAfter = clearAfter;
    return true;
  }

  Future<void> write(String text) async {
    content = text;
    lastWriteWasSensitive = false;
  }

  Future<String?> read() async => canRead ? (content ?? '') : null;

  ClipboardService service({Duration clearAfter = const Duration(seconds: 30)}) =>
      ClipboardService(clearAfter: clearAfter, writeSensitive: writeSensitive, write: write, read: read);
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
const fastKeyDerivation = KeyDerivation(iterations: 1000, minIterations: 1, runInIsolate: false);

PasswordCipher fastCipher() => PasswordCipher(keyDerivation: fastKeyDerivation);

/// Chave mestre já cadastrada no app de teste.
const testMasterKey = 'Chave-mestre-1';

/// Textos quaisquer para o diálogo de digital nos testes.
const testPrompt = BiometricPromptTexts(title: 't', subtitle: 's', cancel: 'c');

SecureVaultKeyRepository vaultKeyRepository(KeyValueStore store, [BiometricKeyStore? biometrics]) =>
    SecureVaultKeyRepository(
      store: store,
      biometrics: biometrics ?? FakeBiometricKeyStore(),
      keyDerivation: fastKeyDerivation,
    );

EncryptedFileEntryRepository entryRepository(KeyValueStore store, BlobStore files) =>
    EncryptedFileEntryRepository(files: files, store: store);

/// Cria a chave mestre e grava [entries] no arquivo cifrado, como um app já em uso.
Future<VaultKey> seedVault(
  KeyValueStore store,
  BlobStore files,
  List<Entry> entries, {
  BiometricKeyStore? biometrics,
  bool withBiometrics = false,
}) async {
  final keys = vaultKeyRepository(store, biometrics);
  final key = await keys.create(testMasterKey);
  await entryRepository(store, files).saveAll(entries, key);
  if (withBiometrics) await keys.enableBiometrics(key, testPrompt);
  return key;
}
