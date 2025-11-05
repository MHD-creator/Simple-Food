import 'package:flutter/material.dart';

PreferredSizeWidget customClientAppBar({required String pageTitle}){
    return AppBar(
      backgroundColor: Colors.green,
      title: Text(pageTitle),
      actions: [
        IconButton(
          onPressed: (){
            
          }, 
          icon: Icon(Icons.person, color: Colors.white)
        )
      ],
    );
}