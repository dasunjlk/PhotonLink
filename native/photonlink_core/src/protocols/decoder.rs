/// Decodes optical input frames back into bytes.
pub trait Decoder {
    type Input;
    type Output;
    type Error;

    fn decode(&self, input: &[Self::Input]) -> Result<Vec<u8>, Self::Error>;
}
