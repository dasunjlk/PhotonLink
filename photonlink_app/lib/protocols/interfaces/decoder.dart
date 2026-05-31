/// Decodes an input stream back into usable output data.
abstract interface class Decoder<TIn, TOut> {
  Stream<TOut> decode(Stream<TIn> input);
}
