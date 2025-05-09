use std::{collections::HashMap, sync::Arc, path::PathBuf};

use processing::{histogram::HistogramParams, process::{extract_events, ProcessParams, TRAPEZOID_DEFAULT}, storage::{load_meta, load_point}, utils::events_to_histogram};
use tokio::sync::Mutex;

#[tokio::main]
async fn main() {

    let algorithm = TRAPEZOID_DEFAULT;

    let points = [
        (
            4.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p0(400s)(HV1=4000)",
        ),
        (
            6.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p1(400s)(HV1=6000)",
        ),
        (
            8.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p2(400s)(HV1=8000)",
        ),
        (
            10.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p3(400s)(HV1=10000)",
        ),
        (
            12.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p4(400s)(HV1=12000)",
        ),
        (
            14.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p5(400s)(HV1=14000)",
        ),
        (
            16.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p6(400s)(HV1=16000)",
        ),
        (
            18.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p7(400s)(HV1=18000)",
        ),
        (
            20.0,
            "/data-fast/numass-server/2024_11/Electrode_1/set_4/p8(400s)(HV1=20000)",
        ),
    ];

    let calibration_data: Arc<Mutex<HashMap<u8, Vec<_>>>> = Arc::new(Mutex::new(HashMap::new()));
    {
        let handles = points
            .iter()
            .map(|(kev, filepath)| {
                let kev = kev.to_owned();
                let filepath = filepath.to_owned();
                let calibration_data = Arc::clone(&calibration_data);
                let algorithm = algorithm.clone();
                tokio::spawn(async move {

                    let filepath = PathBuf::from(filepath);

                    let meta = load_meta(&filepath).await;
                    let point = load_point(&filepath).await;
                    let (events, _) = extract_events(meta, point, &ProcessParams { algorithm, convert_to_kev: false });

                    let histogram  = events_to_histogram(
                        events,
                        HistogramParams { range: 0.0..400.0, bins: 400 });

                    for (ch_id, y) in histogram.channels {
                        let (x, _) = y
                            .clone()
                            .iter()
                            .enumerate()
                            .max_by_key(|(_, amp)| **amp as i64 * 1000)
                            .unwrap();
                        {
                            let mut lock = calibration_data.lock().await;
                            let entry = lock.entry(ch_id).or_default();
                            entry.push((kev as f32, histogram.x[x]));
                        }
                    }
                })
            })
            .collect::<Vec<_>>();

        for handle in handles {
            handle.await.unwrap();
        }
    }

    let calibration_data = calibration_data.lock().await.clone();

    let mut plot = plotly::Plot::new();

    let layout = plotly::Layout::new()
        .title(plotly::common::Title::new("calibration data"))
        .height(1000);
    plot.set_layout(layout);

    let coeffs = (0..7)
        .map(|ch_id| {
            if calibration_data.contains_key(&ch_id) {
                let coeffs = &calibration_data[&ch_id];

                let (x, y): (Vec<_>, Vec<_>) = coeffs.iter().cloned().unzip();

                let (a, b): (f32, f32) = linreg::linear_regression(&y, &x).unwrap();

                let trace = plotly::Scatter::new(x, y).mode(plotly::common::Mode::Markers);

                plot.add_trace(trace);
                [a, b]
            } else {
                [1.0, 0.0]
            }
        })
        .collect::<Vec<_>>();

    plot.show();

    println!("{coeffs:#?}");
}
