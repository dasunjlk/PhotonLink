/// A single data packet for chunked transmission.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Packet {
    pub index: u32,
    pub total: u32,
    pub payload: Vec<u8>,
    pub checksum: u32,
}

/// Splits raw bytes into packets and reassembles them.
pub trait Packetizer {
    type Error;

    fn packetize(&self, data: &[u8]) -> Result<Vec<Packet>, Self::Error>;
    fn assemble(&self, packets: &[Packet]) -> Result<Vec<u8>, Self::Error>;
}
