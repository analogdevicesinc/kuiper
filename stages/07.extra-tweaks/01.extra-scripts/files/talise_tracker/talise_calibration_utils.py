"""
This Python file contains application level calibration methods and procedures for phased
array antenna receiver system using Talise (ADRV9009-ZU11EG). It specifically focuses on
performing gain and phase calibrations. These methods work in conjunction with attributes
and methods from the adrv9009_zu11eg class.
"""
import numpy as np
from numpy.typing import NDArray
import matplotlib.pyplot as plt
from matplotlib.axes import Axes
import time
import logging
import config_talise as config
from typing import Any, Union

logger = logging.getLogger(__name__)

def talise_init(my_talise: Any) -> None:
    """Initialize the Talise SDR with configuration parameters."""
    logger.info("Transmitted baseband complex sinusoid frequency: %s", 
                config.tx_sine_baseband_freq)
    logger.info("Numeric value of discrete amplitude of transmitted signal: %s", 
                config.amplitude_discrete)

    my_talise.load_phase_cal()
    my_talise.load_gain_cal()
   
    if (config.used_rx_channels > 0) and (config.used_rx_channels <= 4):
        my_talise.num_rx_elements = config.used_rx_channels
    else:
        logger.warning("Wrong number of used_rx_channels! Modify config file!")
        my_talise.num_rx_elements = 4

    logger.info("Number of samples per call to rx(): %s", config.num_samps)

    my_talise.rx_enabled_channels = config.rx_channels_used
    my_talise.tx_enabled_channels = config.tx_channels_used

    my_talise.trx_lo = config.lo_freq
    my_talise.trx_lo_chip_b = config.lo_freq
    
    config.sample_rate = my_talise.rx_sample_rate

    my_talise.tx_cyclic_buffer = True

    my_talise.gain_control_mode_chan0 = config.rx_gain_control_mode
    my_talise.gain_control_mode_chan1 = config.rx_gain_control_mode
    my_talise.gain_control_mode_chan0_chip_b = config.rx_gain_control_mode
    my_talise.gain_control_mode_chan1_chip_b = config.rx_gain_control_mode

    my_talise.tx_hardwaregain_chan0 = config.tx_gain
    my_talise.tx_hardwaregain_chan1 = config.tx_unused_channel_gain
    my_talise.tx_hardwaregain_chan0_chip_b = config.tx_unused_channel_gain
    my_talise.tx_hardwaregain_chan1_chip_b = config.tx_unused_channel_gain

    my_talise.rx_hardwaregain_chan0 = config.rx_gain
    my_talise.rx_hardwaregain_chan1 = config.rx_gain
    my_talise.rx_hardwaregain_chan0_chip_b = config.rx_gain
    my_talise.rx_hardwaregain_chan1_chip_b = config.rx_gain

    my_talise.rx_buffer_size = config.num_samps
    my_talise.tx_buffer_size = config.num_samps

    logger.info("Syncing")
    my_talise.mcs_chips()
    logger.info("Done syncing")
    logger.info("Calibrating")
    my_talise.calibrate_rx_qec_en = 1
    my_talise.calibrate_rx_qec_en_chip_b = 1
    my_talise.calibrate_tx_qec_en = 1
    my_talise.calibrate_tx_qec_en_chip_b = 1
    my_talise.calibrate_rx_phase_correction_en_chip_b = 1
    my_talise.calibrate_rx_phase_correction_en = 1
    my_talise.calibrate = 1
    my_talise.calibrate_chip_b = 1
    logger.info("Done calibrating")

def measure_phase_degrees(chan0: NDArray[np.complex128], 
                          chan1: NDArray[np.complex128]) -> np.floating[Any]:
    """Measure phase difference in degrees between two complex signals."""
    errorV: NDArray[np.floating[Any]] = np.angle(chan0 * np.conj(chan1)) * 180 / np.pi
    error: np.floating[Any] = np.mean(errorV)
    return error

def adjust_gain(sdr: Any, 
                samples_list: list[NDArray[np.complex128]]
               ) -> Union[int, list[NDArray[np.complex128]]]:
    """Apply gain calibration to received samples."""
    if len(samples_list) != config.used_rx_channels:
        logger.warning("Wrong number of input arrays, check used_rx_channels in the config file!")
        return 0
    return [samples * sdr.gcal[i] for i, samples in enumerate(samples_list)]

def adjust_phase(sdr: Any, 
                 phase_shift_deg: float, 
                 samples_list: list[NDArray[np.complex128]]
                ) -> Union[int, list[NDArray[np.complex128]]]:
    """Apply phase calibration to received samples."""
    if len(samples_list) != config.used_rx_channels:
        logger.warning("Wrong number of input arrays, check used_rx_channels in the config file!")
        return 0
    # First channel is the reference channel and is not shifted
    adjusted_samples: list[NDArray[np.complex128]] = [samples_list[0]]
    for i in range(1, len(samples_list)):
        phase_rad: np.floating[Any] = np.deg2rad(((phase_shift_deg * i) + 
                                sdr.pcal[i-1]) % 360.0)
        adjusted_samples.append(samples_list[i] * np.exp(1j * phase_rad))
    return adjusted_samples

def generate_tx_sinewave(windowing: bool = False) -> tuple[NDArray[np.floating[Any]], 
                                                           NDArray[np.complex128]]:
    """Generate a complex sinusoidal waveform for transmission."""
    # Calculate time values
    t: NDArray[np.floating[Any]] = np.arange(config.num_samps) / config.sample_rate
   
    # Generate sinusoidal waveform
    phase_shift: float = -np.pi/2  # Shift by -90 degrees
    samples: NDArray[np.complex128] = config.amplitude_discrete * (
        np.cos(2 * np.pi * config.tx_sine_baseband_freq * t + phase_shift) +
        1j * np.sin(2 * np.pi * config.tx_sine_baseband_freq * t + phase_shift)
    )
    if windowing:
        window: NDArray[np.floating[Any]] = np.hanning(len(samples))
        samples *= window
    return t, samples

def plot_channels(ax: Axes, t: NDArray[np.floating[Any]], 
                  rx_samples: list[NDArray[np.complex128]], 
                  num_channels: int
                 ) -> None:
    """Plot I and Q components for each channel."""
    for ch in range(num_channels):
        ax.plot(t, np.real(rx_samples[ch]), label=f"Ch{ch} I (Real)")
        ax.plot(t, np.imag(rx_samples[ch]), label=f"Ch{ch} Q (Imag)")

def do_cal_gain(sdr: Any) -> None:
    """Perform gain calibration."""
    if config.onboard_tx1_used:
        # Generate sinusoidal waveform
        tx_samples: NDArray[np.complex128]
        t: NDArray[np.floating[Any]]
        t, tx_samples = generate_tx_sinewave()

        # Start transmission
        sdr.tx(tx_samples)

        time.sleep(1)  # wait for internal calibrations
    else:
        t: NDArray[np.floating[Any]] = np.arange(config.num_samps) / \
                                                 config.sample_rate
    
    # Clear buffer just to be safe
    for _ in range(2):
        raw_data: list[NDArray[np.complex128]] = sdr.rx()

    # Receive data
    rx_samples_raw: list[NDArray[np.complex128]] = sdr.rx()
    time.sleep(1)

    # Split into individual channels
    rx_samples: list[NDArray[np.complex128]] = [rx_samples_raw[i] 
                                                 for i in range(config.used_rx_channels)]

    # Adjust phase first
    rx_samples = adjust_phase(sdr, 0, rx_samples)

    # Plot before gain calibration
    axs: NDArray[Any]
    _, axs = plt.subplots(nrows=2, sharex=False, figsize=(10, 8))
    manager: plt.FigureManagerBase = plt.get_current_fig_manager()
    try:
        manager.window.attributes('-zoomed', True)
    except AttributeError:
        try:
            manager.window.showMaximized()
        except Exception:
            logger.debug("Fullscreen not supported.")

    plot_channels(axs[0], t, rx_samples, config.used_rx_channels)
    axs[0].legend()
    axs[0].grid(True)
    axs[0].set_title('Rx time domain before Gain Calibration')
    axs[0].set_xlabel('Time [seconds]')
    axs[0].set_ylabel('Amplitude [LSB]')

    # Save received amplitudes from each channel
    amplitudes: NDArray[np.floating[Any]] = np.array([np.max(np.abs(rx_samples[i]))
                           for i in range(config.used_rx_channels)])
    elem_with_max_amplitude: np.intp = np.argmax(amplitudes)
    max_amplitude: np.floating[Any] = amplitudes[elem_with_max_amplitude]

    logger.debug("Amplitudes list: %s", amplitudes)

    # Calculate the calibration coefficients between the amplitude on the channel 
    # with max amplitude and other channels
    amplitude_cal_coeff: NDArray[np.floating[Any]] = max_amplitude / amplitudes
    amplitude_cal_coeff[elem_with_max_amplitude] = 1.0

    # Save gain calibration coefficients and print them
    sdr.gcal = amplitude_cal_coeff.tolist()
    logger.debug("Gain calibration coefficients: %s", amplitude_cal_coeff)
    sdr.save_gain_cal()

    # Apply gain calibration
    rx_samples = adjust_gain(sdr, rx_samples)

    # Plot after gain calibration
    plot_channels(axs[1], t, rx_samples, config.used_rx_channels)
    axs[1].legend()
    axs[1].grid(True)
    axs[1].set_title('Rx time domain after Gain Calibration')
    axs[1].set_xlabel('Time [seconds]')
    axs[1].set_ylabel('Amplitude [LSB]')

    # Stop transmitting
    sdr.tx_destroy_buffer()

    plt.tight_layout()
    logger.info("Application level gain calibration done.")
    logger.info("Close the plot to continue...")
    plt.show()

def do_cal_phase(sdr: Any) -> None:
    """Perform phase calibration."""
    if config.onboard_tx1_used:
        # Generate sinusoidal waveform
        tx_samples: NDArray[np.complex128]
        t: NDArray[np.floating[Any]]
        t, tx_samples = generate_tx_sinewave()
        # Start transmission
        sdr.tx(tx_samples)
        time.sleep(1)  # wait for internal calibrations
    else:
        t: NDArray[np.floating[Any]] = np.arange(config.num_samps) / \
                                                 config.sample_rate

    # Clear buffer just to be safe
    for _ in range(2):
        raw_data: list[NDArray[np.complex128]] = sdr.rx()

    # Receive data
    rx_samples_raw: list[NDArray[np.complex128]] = sdr.rx()

    # Split into individual channels
    rx_samples: list[NDArray[np.complex128]] = [rx_samples_raw[i] 
                                                 for i in range(config.used_rx_channels)]

    # Adjust gain
    rx_samples = adjust_gain(sdr, rx_samples)

    # Plot before phase calibration
    axs: NDArray[Any]
    _, axs = plt.subplots(nrows=2, sharex=False, figsize=(10, 8))
    manager: plt.FigureManagerBase = plt.get_current_fig_manager()
    try:
        manager.window.attributes('-zoomed', True)
    except AttributeError:
        try:
            manager.window.showMaximized()
        except Exception:
            logger.debug("Fullscreen not supported.")

    plot_channels(axs[0], t, rx_samples, config.used_rx_channels)
    axs[0].legend()
    axs[0].grid(True)
    axs[0].set_title('Rx time domain before Phase Calibration')
    axs[0].set_xlabel('Time [seconds]')
    axs[0].set_ylabel('Amplitude [LSB]')

    # Calculate phase differences for all channels relative to ch0
    repeat_ph_calculations: int = 10
    num_channels: int = config.used_rx_channels - 1  # Exclude reference channel 0
    phase_diffs: list[list[np.floating[Any]]] = [[] for _ in range(num_channels)]

    for iteration in range(repeat_ph_calculations):
        rx_samples_raw = sdr.rx()
        rx_samples = [rx_samples_raw[i] for i in range(config.used_rx_channels)]
        logger.debug("Iteration %d:", iteration)
        for ch in range(1, config.used_rx_channels):
            ph_diff: np.floating[Any] = measure_phase_degrees(rx_samples[0], rx_samples[ch])
            phase_diffs[ch-1].append(ph_diff)
            logger.debug("Ph Diff Between ch0 and ch%d: %s", ch, ph_diff)

    # Calculate statistics using numpy
    avg_phase_diffs: list[np.floating[Any]] = [np.mean(diffs) for diffs in phase_diffs]
    max_phase_diffs: list[np.floating[Any]] = [np.max(diffs) for diffs in phase_diffs]
    min_phase_diffs: list[np.floating[Any]] = [np.min(diffs) for diffs in phase_diffs]

    # Save calibration
    sdr.pcal = [float(v) for v in avg_phase_diffs]
    logger.debug("pcal values: %s", sdr.pcal)
    sdr.save_phase_cal()

    # Print statistics
    for ch in range(num_channels):
        logger.debug("Avg ph diff for ch0 - ch%d: %s", ch+1, avg_phase_diffs[ch])
    for ch in range(num_channels):
        logger.debug("Max diff in phase ch0-ch%d: %s", ch+1, max_phase_diffs[ch])
        logger.debug("Min diff in phase ch0-ch%d: %s", ch+1, min_phase_diffs[ch])
    
    # Adjust phase
    rx_samples = adjust_phase(sdr, 0, rx_samples)

    # Plot after phase calibration
    plot_channels(axs[1], t, rx_samples, config.used_rx_channels)
    axs[1].legend()
    axs[1].grid(True)
    axs[1].set_title('Rx time domain after Phase Calibration')
    axs[1].set_xlabel('Time [seconds]')
    axs[1].set_ylabel('Amplitude [LSB]')

    # Stop transmitting
    sdr.tx_destroy_buffer()

    plt.tight_layout()
    logger.info("Application level phase calibration done.")
    logger.info("Close the plot to continue...")
    plt.show()

def calibrate_boresight(sdr: Any) -> None:
    """Perform complete boresight calibration (phase and gain)."""
    logger.info("If you are using antennas, place the transmitting antenna at boresight")
    input("Press Enter to continue...")
    logger.info("Starting application level phase calibration...")
    do_cal_phase(sdr)
    logger.info("Starting application level gain calibration...")
    do_cal_gain(sdr)
