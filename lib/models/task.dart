import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  String title;
  String description;
  DateTime date;
  DateTime timestamp;
  TimeOfDay time;
  bool isEveryDay;
  bool hasTime;

  Task({
    this.title,
    this.description,
    this.date,
    this.timestamp,
    this.time,
    this.isEveryDay,
    this.hasTime,
  });

  factory Task.fromDoc(DocumentSnapshot doc) {
    return Task(
      title: doc['title'],
      description: doc['description'],
      date: (doc['date'] as Timestamp).toDate(),
      timestamp:
          doc['hasTime'] ? (doc['timeStamp'] as Timestamp).toDate() : null,
      time: doc['hasTime']
          ? TimeOfDay.fromDateTime(DateTime.parse(doc['time']))
          : null,
      isEveryDay: doc['isEveryDay'],
      hasTime: doc['hasTime'],
    );
  }
}
