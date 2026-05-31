/// Encodes input data into an output stream suitable for optical transmission.
abstract interface class Encoder<TIn, TOut> {
  Stream<TOut> encode(TIn input);
}
