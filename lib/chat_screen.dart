import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';  // Importamos el paquete para manejar la conexión

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> messages = [];
  TextEditingController _controller = TextEditingController();
  late final GenerativeModel generativeModel;
  bool isConnected = true;  // Variable para verificar el estado de la conexión
  late final Connectivity _connectivity;  // Objeto de conectividad
  late final Stream<List<ConnectivityResult>> _connectivityStream;  // Stream de conectividad

  @override
  void initState() {
    super.initState();
    generativeModel = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: 'TuAPIKey',  // Reemplazar con la clave correcta
    );
    _loadMessages();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;  // Escuchar cambios de conexión
    _checkConnection();  // Verificar el estado de la conexión
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMessages = prefs.getString('chatHistory');

    if (savedMessages != null) {
      List<dynamic> decodedMessages = jsonDecode(savedMessages);
      setState(() {
        messages = decodedMessages.map((msg) {
          return {
            'sender': msg['sender'].toString(),
            'message': msg['message'].toString(),
          };
        }).toList();
      });
    }
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatHistory', jsonEncode(messages));
  }

  Future<void> _sendMessage(String message) async {
    if (message.isNotEmpty && isConnected) {
      setState(() {
        messages.add({'sender': 'Tú', 'message': message});
      });
      _controller.clear();
      await _saveMessages();

      String responseMessage = await _getResponseFromGemini(message);

      setState(() {
        messages.add({'sender': 'Gemini', 'message': responseMessage});
      });
      await _saveMessages();
    } else if (!isConnected) {
      _showNoConnectionMessage();
    }
  }

  Future<String> _getResponseFromGemini(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await generativeModel.generateContent(content);
      return response.text ?? 'Sin respuesta de la IA';
    } catch (e) {
      return 'Error en la comunicación con Gemini: $e';
    }
  }

  Future<void> _checkConnection() async {
    // Verifica el estado inicial de la conexión
    var connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
    });

    // Escucha los cambios en la conectividad
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Verificar si hay alguna conectividad activa
      setState(() {
        isConnected = results.isNotEmpty && results.every((result) => result != ConnectivityResult.none);
      });
    });
  }

  void _showNoConnectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No hay conexión a Internet')),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    bool isUser = message['sender'] == 'Tú';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isUser ? Radius.circular(15) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['sender']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Text(
              message['message']!,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con IA'),
        actions: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: isConnected ? Colors.blueAccent : Colors.grey),
                  onPressed: isConnected
                      ? () {
                          _sendMessage(_controller.text);
                        }
                      : null,  // Si no hay conexión, el botón estará deshabilitado
                ),
              ],
            ),
          ),
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No tienes conexión a Internet',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
