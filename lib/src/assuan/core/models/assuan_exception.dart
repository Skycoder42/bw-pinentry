class AssuanException extends FormatException {
  const AssuanException([super.message, super.source, super.offset]);

  @override
  String toString() => 'AssuanException${super.toString().substring(15)}';
}
