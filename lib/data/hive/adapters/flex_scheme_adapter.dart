import 'package:hive/hive.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class FlexSchemeAdapter extends TypeAdapter<FlexScheme> {
  @override
  final int typeId = 7; // Ensure this ID is unique

  @override
  FlexScheme read(BinaryReader reader) {
    return FlexScheme.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, FlexScheme obj) {
    writer.writeInt(obj.index);
  }
} 