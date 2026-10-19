import 'dart:io';

import 'package:agenda_contatos/helpers/contact_helper.dart';
import 'package:flutter/material.dart';

// import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ContactHelper helper = ContactHelper();
  List<Contact> contacts = [];

  @override
  void initState() {
    // TODO: implement initState
    helper.getAllContacts().then((list){
      setState(() {
        contacts = list;
      });
    });
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   Contact c = Contact();
  //
  //   c.name = "IF Sul de Minas 2";
  //   c.email = "Dani Nazaré";
  //   c.phone = "3500000000";
  //   c.img = "myImage";
  //
  //   helper.saveContact(c);
  //
  //   helper.getAllContacts().then((list) {
  //     print(list.toString());
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contatos"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
       floatingActionButton: FloatingActionButton(
           onPressed: (){},
         child: Icon(Icons.add),
         backgroundColor: Colors.red,
       ),
      body: ListView.builder(
          padding: EdgeInsets.all(10.0),
          itemCount: contacts.length,
          itemBuilder: (context, index){
            return _contactCard(context, index);
          }
      ),
    );
  }

  Widget _contactCard(BuildContext context, int index){
    return GestureDetector(
      child: Card(
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Container(
                  width: 80.0,
                  height: 80.0,
                  decoration:BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: contacts[index].img != null &&
                          contacts[index].img!.isNotEmpty &&
                          File(contacts[index].img!).existsSync()
                          ? FileImage(File(contacts[index].img!))
                          : const AssetImage('images/person.png') as ImageProvider,
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(contacts[index].name??"",
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ), Text(contacts[index].email??"",
                        style: TextStyle(
                          fontSize: 18.0
                        ),
                      ), Text(contacts[index].phone??"",
                        style: TextStyle(
                          fontSize: 18.0
                        ),
                      )
                    ],
                ),
                ),
              ],

        ),
        ),
      ),
    );
  }
}
