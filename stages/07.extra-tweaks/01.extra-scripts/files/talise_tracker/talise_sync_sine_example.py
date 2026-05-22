"""
talise_sync_sine_example.py

This example script demonstrates how to initialize and use a Talise (ADRV9009-ZU11EG) SDR device
using Python. After transmitting a continuous sine wave, the system receives signals from all
4 Rx channels. The script then displays both received time domain signals and the phase difference
between channels continuously.

Main Features:
- Initializes Talise SDR device
- Applies application level calibration for phase and gain alignment
- Transmits continuously a baseband complex sinusoid from Tx channel 0
- Receives continuously IQ data from all 4 Rx channels
- Plots:
    - time-domain waveforms (I channel)
    - phase error between channels
"""
import numpy as np
import logging
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from numpy.typing import NDArray
from collections import deque
from adrv9009_zu11eg import adrv9009_zu11eg
from time import sleep
from talise_calibration_utils import (adjust_phase, adjust_gain, talise_init, 
                                      measure_phase_degrees, calibrate_boresight,
                                      generate_tx_sinewave)
import config_talise as config

logger = logging.getLogger(__name__)

def on_close(event) -> None:
    global running
    running = False
    logger.info("Plot closed, stopping capture.")

# FuncAnimation update function
def update(frame):
    if not running:
        return list(line.values())

    # Receive data from all channels
    iq_data_raw: list[NDArray[np.complex128]] = sdr.rx()

    # Split into individual channels
    iq_data: list[NDArray[np.complex128]] = [iq_data_raw[i] for i in range(n_ch)]

    # Apply calibration using imported functions
    iq_data = adjust_phase(sdr, 10, iq_data)
    iq_data = adjust_gain(sdr, iq_data)

    # Update time-domain plots (display only first num_display_samps points)
    for i in range(n_ch):
        line[i].set_ydata(np.real(iq_data[i][:num_display_samps]))

    ax.relim()
    ax.autoscale_view()

    # Calculate phase differences for all channels relative to channel 0
    for ch in range(1, n_ch):
        ph_err: float = measure_phase_degrees(iq_data[0], iq_data[ch])
        # deque automatically maintains maxlen
        phase_err_arrays[ch-1].appendleft(ph_err)

    # Update phase error plots
    for i, name in enumerate(phase_err_names):
        line[name].set_ydata(list(phase_err_arrays[i]))

    ax2.relim()
    ax2.autoscale_view()

    return list(line.values())

if __name__ == "__main__":
    line: dict = {}
    running: bool = True
    n_ch: int = config.used_rx_channels
    num_display_samps: int = 200
    x: list[int] = list(range(num_display_samps))  # x axis points for time plot
    num_samples_ph_err: int = 100  # Number of points on the phase difference plot

    # Use deques for efficient phase error tracking (automatically maintains fixed size)
    num_phase_diffs: int = n_ch - 1
    phase_err_arrays: list[deque] = [deque([0.0] * num_samples_ph_err,
                                     maxlen=num_samples_ph_err)
                                        for _ in range(num_phase_diffs)]
    phase_err_names: list[str] = [f"ph_diff_ch0_minus_ch{i+1}" 
                                  for i in range(num_phase_diffs)]
    x_ph_err: list[int] = list(range(num_samples_ph_err))

    # Initialize Talise SDR
    sdr: adrv9009_zu11eg = adrv9009_zu11eg(uri=config.talise_address)
    talise_init(sdr)
    # calibrate_boresight(sdr)
    _, samples = generate_tx_sinewave()
    sdr.tx(samples)

    # Throw first few buffers to ensure stable data
    for _ in range(6):
        throw_data = sdr.rx()

    # Create the figure and axes
    fig: plt.Figure
    ax: plt.Axes
    ax2: plt.Axes
    fig, (ax, ax2) = plt.subplots(nrows=2, sharex=False, figsize=(10, 8))
    fig.canvas.mpl_connect("close_event", on_close)

    # Full screen plot
    manager = plt.get_current_fig_manager()
    try:
        manager.window.attributes('-zoomed', True)
    except AttributeError:
        try:
            manager.window.showMaximized()
        except Exception:
            logger.debug("Fullscreen not supported.")

    # Create plot lines for each channel
    for i in range(n_ch):
        line[i], = ax.plot(x, [0]*num_display_samps, label=f"I ch{i}")

    # Configure time-domain plot
    ax.set_xlabel("No. Sample")
    ax.set_ylabel("Amplitude [LSB]")
    ax.grid(which='both', alpha=0.5)
    ax.grid(which='minor', alpha=0.2)
    ax.grid(which='major', alpha=0.5)
    ax.legend(loc="upper left")

    # Create plot lines for phase error
    for i, name in enumerate(phase_err_names):
        line[name], = ax2.plot(x_ph_err, list(phase_err_arrays[i]), label=name)

    ax2.set_ylabel("Phase Error [deg]")
    ax2.set_xlabel("Measurement Index")
    ax2.grid(True)
    ax2.legend(loc="upper right")
    plt.tight_layout()

    # Create animation (update every 500ms)
    ani: animation.FuncAnimation = animation.FuncAnimation(fig, update, interval=500, 
                                                           blit=False,
                                                           cache_frame_data=False)

    # Show plot
    plt.show()

    # Cleanup
    sdr.tx_destroy_buffer()
