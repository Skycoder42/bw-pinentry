import 'assuan_data_reader.dart';
import 'assuan_data_writer.dart';
import 'assuan_message.dart';

abstract interface class AssuanMessageHandler<T extends AssuanMessage> {
  bool hasData(T message);

  void encodeData(T message, AssuanDataWriter writer);

  T decodeData(AssuanDataReader reader);
}
