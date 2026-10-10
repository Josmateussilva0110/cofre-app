import '../config/app_config.dart';

/// Textos exibidos ao usuário (pt-BR). Nenhum texto de UI deve ficar solto nos widgets.
abstract final class AppStrings {
  // Geral
  static const appName = AppConfig.appName;
  static const cancel = 'Cancelar';
  static const save = 'Salvar';
  static const edit = 'Editar';
  static const delete = 'Excluir';
  static const close = 'Fechar';
  static const back = 'Voltar';
  static const showHide = 'Mostrar/ocultar';
  static const optionalSuffix = ' (opcional)';
  static const emptyValue = '—';

  // Navegação
  static const navVault = 'Cofre';
  static const navNewEntry = 'Nova senha';
  static const navSettings = 'Ajustes';

  // Bloqueio
  static const lockSubtitle = 'Digite sua chave mestre para abrir';
  static const masterKeyHint = 'Chave mestre';
  static const unlock = 'Desbloquear';
  static const orSeparator = 'OU';
  static const masterKeyTooShort = 'A chave mestre precisa ter ao menos ${AppConfig.minMasterKeyLength} caracteres.';
  static const masterKeyMismatch = 'As chaves não conferem.';
  static const masterKeyWrong = 'Chave mestre incorreta.';
  static String masterKeyLockedOut(Duration remaining) {
    final seconds = remaining.inSeconds + 1;
    return seconds < 60
        ? 'Muitas tentativas. Tente de novo em $seconds s.'
        : 'Muitas tentativas. Tente de novo em ${(seconds / 60).ceil()} min.';
  }

  static const createKeySubtitle = 'Crie uma chave mestre para proteger o cofre';
  static const masterKeyRepeatHint = 'Repita a chave mestre';
  static const createKeyAction = 'Criar chave mestre';
  static const createKeyWarning =
      'Guarde bem esta chave: ela não pode ser recuperada. Se esquecê-la, será preciso apagar o cofre.';
  static const verifyingKey = 'Verificando…';
  static const creatingKey = 'Protegendo…';
  static const forgotKey = 'Esqueci a chave mestre';
  static const forgotKeyDialogTitle = 'Esqueceu a chave mestre?';
  static String forgotKeyDialogMessage(int count) =>
      'Sem a chave não é possível abrir o cofre. Para continuar, as $count senhas deste aparelho serão apagadas '
      'e você criará uma chave nova. Digite $wipeConfirmationWord para confirmar.';
  static const masterKeyCreated = 'Chave mestre criada';
  static const biometricPrompt = 'Use sua digital para abrir o Cofre';
  static const biometricDisabled = 'Biometria desativada';
  static const biometricDisabledInSettings = 'Biometria desativada em Ajustes';
  static const biometricScanning = 'Lendo digital…';
  static const biometricUse = 'Usar digital';
  static const biometricRecognized = 'Digital reconhecida';
  static const biometricNotEnrolled = 'Nenhuma digital cadastrada no aparelho';
  static const biometricNoHardware = 'Este aparelho não tem leitor de digital';
  static const biometricLockedOut = 'Biometria bloqueada — use a chave mestre';
  static const biometricUnavailable = 'Biometria indisponível no momento';
  static const lockedByInactivity = 'Bloqueado por inatividade';
  static const vaultLocked = 'Cofre bloqueado';
  static const lockAction = 'Bloquear';

  // Cofre
  static const passwordsTitle = 'Senhas';
  static const passwordsUnit = 'senhas';
  static const searchHint = 'Buscar senhas';
  static const layoutWallet = 'Carteira';
  static const layoutGrouped = 'Agrupada A–Z';
  static const allStrong = 'tudo forte';
  static const nothingFound = 'Nada encontrado';
  static const nothingFoundHint = 'Tente outro termo de busca.';
  static const emptyVault = 'Seu cofre está vazio';
  static const emptyVaultHint = 'Toque em “+” para guardar sua primeira senha.';
  static const loadFailed = 'Não foi possível ler o cofre';
  static const loadFailedHint = 'Seus dados não foram alterados. Feche e abra o app novamente.';
  static const moreOptions = 'Mais opções';
  static const noUrl = 'Sem URL';
  static const cardUsernameLabel = 'USUÁRIO';

  static String weakCount(int count) => '$count ${count > 1 ? 'fracas' : 'fraca'}';
  static String groupCount(int count) => '$count ${count > 1 ? 'senhas' : 'senha'}';

  // Ações sobre uma senha
  static const copyPassword = 'Copiar senha';
  static const copyUsername = 'Copiar usuário';
  static const passwordCopied = 'Senha copiada · some em ${AppConfig.clipboardClearSeconds} s';
  static const usernameCopied = 'Usuário copiado';
  static const showHidePassword = 'Mostrar/ocultar senha';
  static const openLinkFailed = 'Não foi possível abrir o link';

  // Detalhe
  static const usernameLabel = 'Usuário';
  static const passwordLabel = 'Senha';
  static const urlLabel = 'URL';
  static const notesLabel = 'Notas';

  static String updatedLabel(DateTime updatedAt, DateTime now) {
    final days = now.difference(updatedAt).inDays;
    if (days <= 0) return 'Atualizada hoje';
    if (days == 1) return 'Atualizada ontem';
    if (days < 30) return 'Atualizada há $days dias';
    return 'Atualizada em ${updatedAt.day} de ${_months[updatedAt.month - 1]}.';
  }

  static const _months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  // Força da senha
  static const strengthWeak = 'Fraca';
  static const strengthMedium = 'Média';
  static const strengthStrong = 'Forte';

  // Exclusão
  static const deleteEntryTitle = 'Excluir senha?';
  static String deleteEntryMessage(String title) => '“$title” será removida permanentemente do cofre.';
  static const entryDeleted = 'Senha excluída';

  // Formulário
  static const newEntryTitle = 'Nova senha';
  static const editEntryTitle = 'Editar senha';
  static const createSubmit = 'Salvar no cofre';
  static const editSubmit = 'Salvar alterações';
  static const titleLabel = 'Título';
  static const titleHint = 'Ex.: Gmail, Banco, Wi-Fi';
  static const usernameHint = 'E-mail, login ou CPF';
  static const passwordHint = '••••••••';
  static const urlHint = 'exemplo.com.br';
  static const notesHint = 'Perguntas de segurança, PIN, observações…';
  static const generatePassword = 'Gerar';
  static const titleRequired = 'Informe um título';
  static const usernameRequired = 'Informe o usuário';
  static const passwordRequired = 'Informe a senha';
  static const entryCreated = 'Senha salva no cofre';
  static const entryUpdated = 'Senha atualizada';
  static const saveFailed = 'Não foi possível salvar';

  // Ajustes
  static const settingsTitle = 'Ajustes';
  static const appearanceSection = 'Aparência';
  static const themeLight = 'Claro';
  static const themeDark = 'Escuro';
  static const themeSystem = 'Sistema';
  static const securitySection = 'Segurança';
  static const autoLockTitle = 'Bloqueio por inatividade';
  static const autoLockOff = 'Bloqueio automático desligado';
  static const autoLockNever = 'Nunca';
  static String autoLockDescription(int minutes) => 'Bloqueia após $minutes min sem uso';
  static String autoLockOption(int minutes) => minutes == 0 ? autoLockNever : '$minutes min';
  static const biometricsTitle = 'Desbloquear com digital';
  static const biometricsOn = 'Ativada';
  static const biometricsOff = 'Desativada — use a chave mestre';
  static const backupSection = 'Backup';
  static const exportTitle = 'Exportar cofre';
  static String exportDescription(int count) => 'Salva um arquivo criptografado com $count senhas';
  static String exportDone(int count) => 'Cofre exportado · $count senhas';
  static const exportFailed = 'Não foi possível exportar';
  static const importTitle = 'Importar cofre';
  static const importDescription = 'Adiciona senhas de um backup';
  static String importDone(int count) => '$count senhas importadas';
  static const importInvalid = 'Arquivo inválido';

  // Senha do backup
  static const exportPasswordTitle = 'Proteger backup';
  static const exportPasswordMessage =
      'Crie uma senha para criptografar o arquivo. Ela será pedida para importar; '
      'sem ela não há como recuperar as senhas.';
  static const exportPasswordAction = 'Exportar';
  static const importPasswordTitle = 'Backup protegido';
  static const importPasswordMessage = 'Digite a senha usada ao exportar este arquivo.';
  static const importPasswordAction = 'Importar';
  static const backupPasswordHint = 'Senha do backup';
  static const backupPasswordRepeatHint = 'Repita a senha';
  static const backupWrongPassword = 'Senha incorreta ou arquivo alterado.';
  static const passwordsDoNotMatch = 'As senhas não conferem.';
  static String passwordTooShort(int minLength) => 'Use ao menos $minLength caracteres.';
  static const encryptingBackup = 'Criptografando backup…';
  static const decryptingBackup = 'Abrindo backup…';
  static const dangerSection = 'Zona de perigo';
  static const wipeTitle = 'Apagar cofre';
  static const wipeDescription = 'Remove todas as senhas deste aparelho';
  static const wipeDialogTitle = 'Apagar todo o cofre?';
  static String wipeDialogMessage(int count) =>
      'Todas as $count senhas serão apagadas deste aparelho. Exporte um backup antes. '
      'Digite $wipeConfirmationWord para confirmar.';
  static const wipeConfirmationWord = 'APAGAR';
  static const wipeConfirmationHint = 'Digite $wipeConfirmationWord';
  static const wipeAction = 'Apagar';
  static const vaultWiped = 'Cofre apagado';
  static const versionLabel = '${AppConfig.appName} · versão ${AppConfig.appVersion}';
}
