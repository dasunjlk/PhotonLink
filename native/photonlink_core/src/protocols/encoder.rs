/// Encodes input bytes into optical output frames.
pub trait Encoder {
    type Input;
    type Output;
    type Error;

    fn encode(&self, input: Self::Input) -> Result<Vec<Self::Output>, Self::Error>;
}
