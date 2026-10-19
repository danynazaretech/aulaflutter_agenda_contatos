# aulaflutter_agenda_contatos

# CRUD com SQLite e imagens no Flutter

**Projeto:** Agenda de Contatos
**Duração sugerida:** ~100 minutos

---

## 1. Objetivos da aula

Ao final, o aluno deve ser capaz de:

- Explicar o que é CRUD e como ele se aplica ao SQLite.
- Criar um banco local com `sqflite` e um modelo de dados (`Contact`).
- Listar os contatos na tela com `ListView.builder`.
- Associar uma imagem a um contato, guardando o **caminho** dela no banco.

---

## 2. Visão geral do projeto

| Arquivo | Papel |
|---|---|
| `main.dart` | Inicializa o app (e o SQLite via FFI no desktop) |
| `helpers/contact_helper.dart` | Banco de dados + modelo `Contact` |
| `ui/home_page.dart` | Tela com a lista de contatos |

Fluxo para desenhar no quadro:

```
Tela  →  Helper  →  SQLite  →  Helper  →  Tela
```

---

## 3. Parte 1: o banco de dados (`contact_helper.dart`)

### a) Constantes das colunas

```dart
final String idColumn = "idColumn";
final String nameColumn = "nameColumn";
final String emailColumn = "emailColumn";
final String phoneColumn = "phoneColumn";
final String imgColumn = "imgColumn";
final String contactTable = "contactTable";
```

Os nomes ficam em variáveis para evitar erros de digitação nas queries.

### b) Singleton

```dart
static final ContactHelper _instance = ContactHelper.internal();
factory ContactHelper() => _instance;
ContactHelper.internal();
```

Garante **uma única instância** do helper e, portanto, uma única conexão com o banco.

> **Pergunta para a turma:** o que aconteceria se cada tela abrisse sua própria conexão?

### c) Getter `db` com inicialização preguiçosa (lazy)

```dart
Database? _db;

Future<Database> get db async {
  if (_db != null) {
    return _db!;
  } else {
    _db = await initDb();
    return _db!;
  }
}
```

O banco só é aberto na primeira vez que alguém precisa dele.

### d) `Future` e `async/await`

Abrir o banco acessa o armazenamento do aparelho e leva tempo. Em vez de travar o app esperando, o Dart permite aguardar a operação com `Future` e `await`.

**Analogia:** abrir a agenda de contatos do celular. O app não congela; ele mostra a tela e preenche a lista quando os dados chegam.

### e) `initDb` e `onCreate`

```dart
Future<Database> initDb() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, "contacts2.db");

  return openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int newerVersion) async {
      await db.execute(
        """CREATE TABLE $contactTable($idColumn INTEGER PRIMARY KEY AUTOINCREMENT, $nameColumn TEXT,
           $emailColumn TEXT, $phoneColumn TEXT, $imgColumn TEXT)""",
      );
    },
  );
}
```

- `getDatabasesPath()` + `join()` montam o caminho do arquivo `.db`.
- `onCreate` roda **somente na primeira vez**, criando a tabela.

### f) Modelo `Contact`

```dart
Contact.fromMap(Map<String, Object?> map) { ... }   // linha do banco  → objeto
Map<String, Object?> toMap() { ... }                // objeto → linha do banco
```

É a "tradução" entre o mundo do banco (mapas) e o mundo do app (objetos).

---

## 4. O CRUD na prática

| Letra | Operação | Método do projeto | SQL por trás |
|---|---|---|---|
| **C**reate | Criar | `saveContact` | `INSERT` |
| **R**ead | Ler | `getContact`, `getAllContacts`, `getNumber` | `SELECT` |
| **U**pdate | Atualizar | `updateContact` | `UPDATE ... WHERE id = ?` |
| **D**elete | Excluir | `deleteContact` | `DELETE ... WHERE id = ?` |

### Pontos para destacar

- `where: "$idColumn = ?"` com `whereArgs` evita **SQL injection**.
- `insert` devolve o id gerado (AUTOINCREMENT), por isso `saveContact` faz `contact.id = await ...`.
- `update` e `delete` devolvem o **número de linhas afetadas**.

### Exemplos de cada operação

```dart
// CREATE
Contact c = Contact();
c.name = "Maria";
c.email = "maria@email.com";
c.phone = "35999999999";
await helper.saveContact(c);

// READ
List<Contact> todos = await helper.getAllContacts();
Contact? um = await helper.getContact(1);
int? total = await helper.getNumber();

// UPDATE
c.name = "Maria Silva";
await helper.updateContact(c);

// DELETE
await helper.deleteContact(c.id!);
```

### Demonstração ao vivo

O trecho comentado do `initState` serve para isso:

1. Descomente, rode e crie um contato.
2. Imprima a lista no console.
3. Remova o trecho e mostre a lista aparecendo na tela.

Isso fecha o ciclo **salvar → ler → exibir**.

---

## 5. Parte 2: exibindo a lista (`home_page.dart`)

- `initState` chama `getAllContacts().then(...)` e usa `setState` para redesenhar quando os dados chegam.
- `ListView.builder` constrói apenas os itens visíveis (eficiente em listas grandes).
- `_contactCard` monta cada item com `Card` + `Row` (foto à esquerda, textos à direita).
- O operador `??` (`contacts[index].name ?? ""`) trata valores nulos (null safety).

---

## 6. Parte 3: como adicionar uma imagem

### Ideia central

**Não guardamos a imagem no banco. Guardamos o caminho (path) dela, como texto.** Por isso `imgColumn` é `TEXT`.

### A leitura já está pronta

No `Container` da foto:

```dart
image: contacts[index].img != null &&
        contacts[index].img!.isNotEmpty &&
        File(contacts[index].img!).existsSync()
    ? FileImage(File(contacts[index].img!))
    : const AssetImage('images/person.png') as ImageProvider,
```

Se existe um arquivo no caminho salvo, mostra a foto do contato; senão, mostra a imagem padrão. Falta a **escolha** da imagem.

### Passo a passo

**1) Dependências (`pubspec.yaml`)**

```yaml
dependencies:
  image_picker: ^1.1.2
  path_provider: ^2.1.4
```

**2) Declarar o asset padrão**

```yaml
flutter:
  assets:
    - images/person.png
```

**3) Escolher a imagem** (na tela de cadastro/edição)

```dart
import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

Future<void> _pickImage() async {
  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
  if (file == null) return; // usuário cancelou

  setState(() {
    _editedContact.img = file.path;
  });
}
```

**4) (Recomendado) Copiar para uma pasta permanente do app**

O caminho devolvido pelo picker pode ser temporário, e o arquivo pode sumir depois.

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> _saveImagePermanently(String originalPath) async {
  final dir = await getApplicationDocumentsDirectory();
  final newPath = p.join(dir.path, p.basename(originalPath));
  await File(originalPath).copy(newPath);
  return newPath;
}
```

E no `_pickImage`:

```dart
_editedContact.img = await _saveImagePermanently(file.path);
```

**5) Salvar o contato**

Use `saveContact` (novo) ou `updateContact` (edição). A `HomePage` mostra a foto automaticamente ao recarregar a lista.

> **Observação:** em desktop (Linux/Windows/macOS), `ImageSource.camera` não funciona bem. Prefira `gallery` na demonstração.

---

## 7. Ajustes no código antes da aula

1. **`initState` sem `super.initState()`.** Deve ser a primeira linha do método. O `// TODO` pode sair.
2. **Imports.** A `HomePage` importa `helpers/contact_helper.dart` e o `main.dart` importa `ui/home_page.dart`. Confirme que `lib/helpers` e `lib/ui` existem assim.
3. **`onPressed: () {}` vazio no botão `+`.** É o gancho para a tela de cadastro, onde entra a escolha de imagem.
4. **`toString()` do `Contact` não imprime o `phone`.** Confunde na demonstração com `print`.
5. **Não há Update nem Delete na interface.** O `GestureDetector` do card não tem `onTap`. Sugestão: abrir a tela de edição no toque e oferecer exclusão dentro dela.
6. **`setState` após `await`.** Em apps maiores, vale checar `if (mounted)`. Bom ponto para mencionar rapidamente.
7. **`getAllContacts` roda só no `initState`.** Após salvar na tela de cadastro, é preciso recarregar a lista, por exemplo `await Navigator.push(...)` seguido de uma função `_getAllContacts()`.

### `initState` corrigido

```dart
@override
void initState() {
  super.initState();
  _getAllContacts();
}

void _getAllContacts() {
  helper.getAllContacts().then((list) {
    if (!mounted) return;
    setState(() {
      contacts = list;
    });
  });
}
```

---

## 8. Cronograma sugerido (~100 min)

| Tempo | Atividade |
|---|---|
| 10 min | O que é persistência local, SQLite e CRUD |
| 25 min | Explicação do `contact_helper.dart` |
| 15 min | Demo: salvar e listar via console |
| 15 min | Exibir na `HomePage` com `ListView.builder` |
| 25 min | Imagem: `image_picker`, path e `FileImage` |
| 10 min | Recapitulação e exercício |

---

## 9. Exercícios propostos

1. Implementar a tela de cadastro (nome, e-mail, telefone, foto).
2. Implementar editar e excluir com confirmação (`AlertDialog`).
3. Ordenar a lista por nome (`orderBy: "$nameColumn COLLATE NOCASE"` no `query`).
4. Mostrar no `AppBar` o total de contatos usando `getNumber()`.

---

## 10. Resumo para fixação

- **CRUD** = Create, Read, Update, Delete.
- O **helper** isola o acesso ao banco; a **tela** só chama métodos dele.
- `Future` + `await` evitam travar o app em operações lentas.
- `toMap` / `fromMap` convertem entre objeto e linha do banco.
- Imagem no banco = **caminho (texto)**, não o arquivo em si.
- Copie a imagem para uma pasta permanente do app para ela não sumir.
