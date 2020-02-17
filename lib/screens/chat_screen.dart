import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText;  // the actual text message data

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser()async {
    try {
      final user = await _auth.currentUser();
      if( user != null) {
          loggedInUser = user;
          print(loggedInUser.email);
        }
    }  catch (e) {
      print(e);
    }
  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) { //snapshot - list of future
      for (var message in snapshot.documents) {
        print(message.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
                //Implement logout functionality
//                _auth.signOut();
//                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,  // pushes the text entery field and Send button to the bottom
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,  // sets up text clearing on send
                      onChanged: (value) {
                        messageText = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();  //clears the text entry field on send
                      //Implement send functionality. messageText + loggedInUser.email
                      _firestore.collection('messages').add({  // the names: "messages", "sender" and "text" are gotten from console.firebase
                          'text': messageText,
                          'sender': loggedInUser.email,
                        'dateTime': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(  //https://www.udemy.com/course/flutter-bootcamp-with-dart/learn/lecture/14486724#overview
      stream: _firestore.collection('messages').orderBy('dateTime').snapshots(),  //stream of query snapshots
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.lightBlueAccent,
                  )
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for(var message in messages){
          final messageText = message.data['text']; // text and sender correspond to the fields in Firebase(like a json http response)
          final messageSender = message.data['sender'];

          final currentUser = loggedInUser.email;

          if(currentUser == messageSender){
             // The message from the logged in user.
          }

          final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,  // sets true if current and sender and the same, false if the message is from someone else
              );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {

  MessageBubble({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {  https://www.udemy.com/course/flutter-bootcamp-with-dart/learn/lecture/14511202#overview
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender, style: TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular(30.0), bottomRight: Radius.circular(30.0) )
                    : BorderRadius.only(topRight: Radius.circular(30.0), bottomLeft: Radius.circular(30.0), bottomRight: Radius.circular(30.0) ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            //color: Colors.lightBlueAccent,
            child: Padding(
              padding:  EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text('$text',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                        fontSize: 15.0
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


