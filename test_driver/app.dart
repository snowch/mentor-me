// test_driver/app.dart
// Entry point for Gherkin integration tests
// This file starts the app in a testable configuration

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:mentor_me/main.dart' as app;

void main() {
  // Enable Flutter Driver extension
  // This allows the Gherkin runner to interact with the app
  enableFlutterDriverExtension();

  // Run the app
  app.main();
}
