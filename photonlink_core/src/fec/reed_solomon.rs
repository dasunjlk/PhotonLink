use std::collections::HashSet;

use crate::error::{CoreError, CoreResult};
use crate::fec::galois_field;

/// Systematic Reed-Solomon erasure codec — exact Dart port.
pub fn encode_block(
    data_symbols: &[Vec<u8>],
    parity_count: usize,
    symbol_length: usize,
) -> CoreResult<Vec<Vec<u8>>> {
    let k = data_symbols.len();
    let m = parity_count;
    if k < 1 || m < 1 {
        return Err(CoreError::InvalidInput(
            "dataCount and parityCount must be >= 1".into(),
        ));
    }
    if k + m > 255 {
        return Err(CoreError::InvalidInput("k + m must be <= 255".into()));
    }

    let parity_gen = parity_generator_matrix(k, m)?;
    let mut parity = vec![vec![0u8; symbol_length]; m];

    for row in 0..m {
        for b in 0..symbol_length {
            let mut sum = 0u8;
            for col in 0..k {
                sum = galois_field::add(sum, galois_field::mul(parity_gen[row][col], data_symbols[col][b]));
            }
            parity[row][b] = sum;
        }
    }

    Ok(parity)
}

pub fn decode_block(
    data_count: usize,
    parity_count: usize,
    symbol_length: usize,
    erasures: &[usize],
    available: &std::collections::HashMap<usize, Vec<u8>>,
) -> CoreResult<Option<Vec<Vec<u8>>>> {
    let k = data_count;
    let m = parity_count;
    let erasure_set: HashSet<usize> = erasures.iter().copied().collect();

    let mut all_data_present = true;
    for i in 0..k {
        if erasure_set.contains(&i) || !available.contains_key(&i) {
            all_data_present = false;
            break;
        }
    }
    if all_data_present {
        return Ok(Some(
            (0..k)
                .map(|i| available.get(&i).cloned().unwrap())
                .collect(),
        ));
    }

    if available.len() < k || erasures.len() > m {
        return Ok(None);
    }

    let parity_gen = parity_generator_matrix(k, m)?;

    enum Equation {
        Direct { index: usize, value: Vec<u8> },
        Parity { coeffs: Vec<u8>, value: Vec<u8> },
    }

    let mut equations: Vec<Equation> = Vec::new();

    for i in 0..k {
        if !erasure_set.contains(&i) && available.contains_key(&i) {
            equations.push(Equation::Direct {
                index: i,
                value: available[&i].clone(),
            });
        }
    }

    for p in 0..m {
        let idx = k + p;
        if !erasure_set.contains(&idx) && available.contains_key(&idx) {
            equations.push(Equation::Parity {
                coeffs: parity_gen[p].clone(),
                value: available[&idx].clone(),
            });
        }
    }

    if equations.len() < k {
        return Ok(None);
    }

    let selected: Vec<_> = equations.into_iter().take(k).collect();
    let mut recovered = vec![vec![0u8; symbol_length]; k];

    for b in 0..symbol_length {
        let mut matrix = vec![vec![0u8; k]; k];
        let mut values = vec![0u8; k];

        for r in 0..k {
            match &selected[r] {
                Equation::Direct { index, value } => {
                    matrix[r][*index] = 1;
                    values[r] = value[b];
                }
                Equation::Parity { coeffs, value } => {
                    for c in 0..k {
                        matrix[r][c] = coeffs[c];
                    }
                    values[r] = value[b];
                }
            }
        }

        let inverse = match invert_matrix(&matrix) {
            Some(inv) => inv,
            None => return Ok(None),
        };

        for col in 0..k {
            let mut sum = 0u8;
            for row in 0..k {
                sum = galois_field::add(sum, galois_field::mul(inverse[col][row], values[row]));
            }
            recovered[col][b] = sum;
        }
    }

    Ok(Some(recovered))
}

fn vandermonde_matrix(n: usize, k: usize) -> Vec<Vec<u8>> {
    (0..n)
        .map(|i| {
            let eval = (i + 1) as u8;
            (0..k).map(|j| galois_field::pow(eval, j as u32)).collect()
        })
        .collect()
}

fn parity_generator_matrix(k: usize, m: usize) -> CoreResult<Vec<Vec<u8>>> {
    let v = vandermonde_matrix(k + m, k);
    let top = &v[0..k];
    let bottom = &v[k..k + m];
    let inv_top = invert_matrix(top).ok_or_else(|| {
        CoreError::RecoveryFailed("Singular Vandermonde top matrix".into())
    })?;
    Ok(multiply_matrices(bottom, &inv_top))
}

fn multiply_matrices(a: &[Vec<u8>], b: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let rows = a.len();
    let cols = b[0].len();
    let inner = b.len();
    (0..rows)
        .map(|i| {
            (0..cols)
                .map(|j| {
                    let mut sum = 0u8;
                    for t in 0..inner {
                        sum = galois_field::add(sum, galois_field::mul(a[i][t], b[t][j]));
                    }
                    sum
                })
                .collect()
        })
        .collect()
}

fn invert_matrix(matrix: &[Vec<u8>]) -> Option<Vec<Vec<u8>>> {
    let n = matrix.len();
    let mut aug: Vec<Vec<u8>> = matrix
        .iter()
        .enumerate()
        .map(|(i, row)| {
            let mut r = row.clone();
            for j in 0..n {
                r.push(if i == j { 1 } else { 0 });
            }
            r
        })
        .collect();

    for col in 0..n {
        let mut pivot_row = col;
        while pivot_row < n && aug[pivot_row][col] == 0 {
            pivot_row += 1;
        }
        if pivot_row == n {
            return None;
        }

        if pivot_row != col {
            aug.swap(col, pivot_row);
        }

        let inv_pivot = galois_field::inverse(aug[col][col]).ok()?;
        for j in 0..2 * n {
            aug[col][j] = galois_field::mul(aug[col][j], inv_pivot);
        }

        for row in 0..n {
            if row == col {
                continue;
            }
            let factor = aug[row][col];
            if factor == 0 {
                continue;
            }
            for j in 0..2 * n {
                aug[row][j] = galois_field::sub(
                    aug[row][j],
                    galois_field::mul(factor, aug[col][j]),
                );
            }
        }
    }

    Some(
        aug.iter()
            .map(|row| row[n..2 * n].to_vec())
            .collect(),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn single_erasure_recovery() {
        let k = 3;
        let m = 2;
        let sym_len = 4;
        let data: Vec<Vec<u8>> = (0..k)
            .map(|i| vec![i as u8; sym_len])
            .collect();
        let parity = encode_block(&data, m, sym_len).unwrap();

        let mut available = std::collections::HashMap::new();
        available.insert(0, data[0].clone());
        available.insert(2, data[2].clone());
        available.insert(3, parity[0].clone());
        available.insert(4, parity[1].clone());

        let recovered = decode_block(k, m, sym_len, &[1], &available)
            .unwrap()
            .unwrap();
        assert_eq!(recovered[1], data[1]);
    }
}
