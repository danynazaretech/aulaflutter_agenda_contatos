import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart';

// Colunas do banco de dados na nossa agenda de contatos
final String idColumn = "idColumn";
final String nameColumn = "nameColumn";
final String emailColumn = "emailColumn";
final String phoneColumn = "phoneColumn";
final String imgColumn = "imgColumn";

final String contactTable = "contactTable";

class ContactHelper {
  static final ContactHelper _instance = ContactHelper.internal();

  factory ContactHelper() => _instance;

  ContactHelper.internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    /*
    Pense na sua agenda de contatos: para abrir o banco SQLite, o aplicativo precisa acessar 
    o armazenamento do dispositivo. Isso pode levar algum tempo. Em vez de bloquear o aplicativo 
    até terminar, o Dart permite aguardar essa operação usando Future e await.
    */
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

  Future<Contact> saveContact(Contact contact) async {
    Database dbContact = await db;
    contact.id = await dbContact.insert(contactTable, contact.toMap());
    return contact;
  }

  // Buscar contato pelo ID
  Future<Contact?> getContact(int id) async {
    final Database dbContact = await db;

    final List<Map<String, Object?>> maps = await dbContact.query(
      contactTable,
      columns: [idColumn, nameColumn, emailColumn, phoneColumn, imgColumn],
      where: "$idColumn = ?",
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }

    return null;
  }

  Future<int?> deleteContact(int id) async {
    Database dbContact = await db;
    return await dbContact.delete(
      contactTable,
      where: "$idColumn = ?",
      whereArgs: [id],
    );
  }

  Future<List<Contact>> getAllContacts() async {
    final Database dbContact = await db;

    final List<Map<String, Object?>> listMap = await dbContact.query(
      contactTable,
    );

    return listMap.map((map) => Contact.fromMap(map)).toList();
  }

  Future<int?> getNumber() async {
    Database dbContact = await db;
    return Sqflite.firstIntValue(
      await dbContact.rawQuery("SELECT COUNT(*) FROM $contactTable"),
    );
  }

  Future close() async {
    Database dbContact = await db;
    await dbContact.close();
  }

  Future<int?> updateContact(Contact contact) async {
    Database dbContact = await db;
    return await dbContact.update(
      contactTable,
      contact.toMap(),
      where: "$idColumn = ?",
      whereArgs: [contact.id],
    );
  }
}

class Contact {
  // Responsável por modelar quais dados da agenda de contatos o usuário pode manipular

  int? id;
  String? name;
  String? email;
  String? phone;
  String? img;

  Contact();

  Contact.fromMap(Map<String, Object?> map) {
    id = map[idColumn] as int?;
    name = map[nameColumn] as String?;
    email = map[emailColumn] as String?;
    phone = map[phoneColumn] as String?;
    img = map[imgColumn] as String?;
  }

  Map<String, Object?> toMap() {
    Map<String, Object?> map = {
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
      imgColumn: img,
    };

    if (id != null) {
      map[idColumn] = id;
    }
    return map;
  }

  @override
  String toString() {
    return "Contact(id: $id, name: $name, email: $email, img: $img)";
  }
}
