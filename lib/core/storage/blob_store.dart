import 'dart:io';

/// Arquivos binários na pasta privada do app.
abstract interface class BlobStore {
  Future<List<int>?> read(String name);

  /// Grava sem risco de corromper: escreve num temporário e renomeia. Se [backupName] for informado, a versão
  /// anterior é preservada com esse nome.
  Future<void> writeAtomic(String name, List<int> bytes, {String? backupName});

  /// Apaga o arquivo e qualquer temporário que tenha sobrado de uma gravação interrompida.
  Future<void> delete(String name);
}

/// Implementação em disco. [directory] deve ser privado do app (ex.: `getApplicationSupportDirectory`).
class FileBlobStore implements BlobStore {
  FileBlobStore(this._directory);

  static const _tempSuffix = '.tmp';

  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async => File('${(await _directory()).path}${Platform.pathSeparator}$name');

  @override
  Future<List<int>?> read(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> writeAtomic(String name, List<int> bytes, {String? backupName}) async {
    final target = await _file(name);
    final temp = await _file('$name$_tempSuffix');
    await temp.parent.create(recursive: true);
    await temp.writeAsBytes(bytes, flush: true);
    if (backupName != null && await target.exists()) await target.rename((await _file(backupName)).path);
    await temp.rename(target.path);
  }

  @override
  Future<void> delete(String name) async {
    for (final file in [await _file(name), await _file('$name$_tempSuffix')]) {
      if (await file.exists()) await file.delete();
    }
  }
}
