/// Galois Field GF(2^8) with primitive polynomial 0x11D — exact Dart port.
const GENERATOR: u16 = 0x11D;

static EXP: std::sync::OnceLock<[u8; 512]> = std::sync::OnceLock::new();
static LOG: std::sync::OnceLock<[u8; 256]> = std::sync::OnceLock::new();

fn exp_table() -> &'static [u8; 512] {
    EXP.get_or_init(|| {
        let mut exp = [0u8; 512];
        let mut x: u16 = 1;
        for i in 0..255 {
            exp[i] = x as u8;
            x <<= 1;
            if x & 0x100 != 0 {
                x ^= GENERATOR;
            }
        }
        for i in 255..512 {
            exp[i] = exp[i - 255];
        }
        exp
    })
}

fn log_table() -> &'static [u8; 256] {
    LOG.get_or_init(|| {
        let exp = exp_table();
        let mut log = [0u8; 256];
        for i in 0..255 {
            log[exp[i] as usize] = i as u8;
        }
        log
    })
}

pub fn add(a: u8, b: u8) -> u8 {
    a ^ b
}

pub fn sub(a: u8, b: u8) -> u8 {
    a ^ b
}

pub fn mul(a: u8, b: u8) -> u8 {
    if a == 0 || b == 0 {
        return 0;
    }
    let exp = exp_table();
    let log = log_table();
    exp[(log[a as usize] as usize + log[b as usize] as usize) % 255]
}

pub fn div(a: u8, b: u8) -> Result<u8, String> {
    if b == 0 {
        return Err("Division by zero in GF(256)".into());
    }
    if a == 0 {
        return Ok(0);
    }
    let exp = exp_table();
    let log = log_table();
    Ok(exp[((log[a as usize] as i32 - log[b as usize] as i32 + 255) % 255) as usize])
}

pub fn pow(base: u8, exponent: u32) -> u8 {
    if exponent == 0 {
        return 1;
    }
    if base == 0 {
        return 0;
    }
    let exp = exp_table();
    let log = log_table();
    exp[((log[base as usize] as u32 * exponent) % 255) as usize]
}

pub fn inverse(a: u8) -> Result<u8, String> {
    if a == 0 {
        return Err("Cannot invert zero in GF(256)".into());
    }
    let exp = exp_table();
    let log = log_table();
    Ok(exp[(255 - log[a as usize] as usize) % 255])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mul_identity() {
        assert_eq!(mul(1, 5), 5);
        assert_eq!(mul(5, 0), 0);
    }
}
