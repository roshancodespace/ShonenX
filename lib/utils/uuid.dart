import 'package:uuid/uuid.dart';

String generateRandomId() {
  var uuid = Uuid();
  return uuid.v4(); // Generates a random UUID
}
