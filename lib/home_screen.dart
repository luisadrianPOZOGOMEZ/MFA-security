import 'package:flutter/material.dart';
import 'package:chatbot/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presentación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(// Reemplaza con tu imagen
              backgroundImage: AssetImage('assets/63227.png'),
            ),
            SizedBox(height: 20),
            Text(
              'Ingeniería en Software',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Luis Adrián Pozo Gómez 221218\nProgramación Movil\n9A\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Text('Ir al Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
