import 'assuan_data_reader.dart';
import 'assuan_data_writer.dart';
import 'assuan_message.dart';

abstract interface class AssuanMessageHandler<T extends AssuanMessage>() {
  bool hasData(T message);

  void encodeData(T message, AssuanDataWriter writer);

  T decodeData(AssuanDataReader reader);
}

abstract class const EmptyAssuanMessageHandler<T extends AssuanMessage>(
  final T Function() _factory,
) implements AssuanMessageHandler<T> {
  @override
  bool hasData(_) => false;

  @override
  void encodeData(_, _) {}

  @override
  T decodeData(_) => _factory();
}
