/// Computes and validates checksums for data integrity.
pub trait ChecksumValidator {
    fn compute(&self, data: &[u8]) -> u32;
    fn validate(&self, data: &[u8], expected: u32) -> bool {
        self.compute(data) == expected
    }
}
