use std::f32::consts::PI;

// Common geometries

pub static PLANE_INDICES: [u16; 6] = [0, 1, 2, 2, 3, 0];
pub static PLANE_VERTICES: [f32; 12] = [
    1.0, -1.0, 0.0, //
    1.0, 1.0, 0.0, //
    -1.0, 1.0, 0.0, //
    -1.0, -1.0, 0.0,
];
pub static LINE_INDICES: [u16; 6] = [0, 1, 2, 2, 3, 0];
pub static LINE_VERTICES: [f32; 12] = [
    0.03, 0.0, 0.0, //
    0.03, 0.4, 0.0, //
    -0.03, 0.4, 0.0, //
    -0.03, 0.0, 0.0,
];

// Points

pub fn new_points(rows: i32, cols: i32) -> Vec<f32> {
    let mut data = Vec::with_capacity((rows * cols * 3) as usize);
    let step_x = 1.0 / (rows as f32);
    let step_y = 1.0 / (cols as f32);

    for v in 0..cols {
        for u in 0..rows {
            let x: f32 = step_x * (u as f32) * 2.0 - 1.0;
            let y: f32 = step_y * (v as f32) * 2.0 - 1.0;
            data.push(x);
            data.push(y);
            data.push(0.0);
        }
    }

    data
}

pub fn make_sine_vector_field(rows: i32, cols: i32) -> Vec<f32> {
    let mut data = Vec::with_capacity((rows * cols * 4) as usize);
    let step_x = 1.0 / (rows as f32);
    let step_y = 1.0 / (cols as f32);

    for v in 0..cols {
        for u in 0..rows {
            let x = step_x * (u as f32) * 2.0 * -1.0;
            let y = step_y * (v as f32) * 2.0 * -1.0;

            // Swirrlies
            data.push(0.3 * (2.0 * PI * y).sin());
            data.push(0.3 * (2.0 * PI * x).sin());
            data.push(0.0);
            data.push(1.0);
        }
    }

    data
}
