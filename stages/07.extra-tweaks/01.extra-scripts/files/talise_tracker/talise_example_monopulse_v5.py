"""
talise_example_monopulse_v5.py

DOA (Direction of Arrival) and Monopulse tracking example for Talise (ADRV9009-ZU11EG).
Supports multiple modes via command line argument:
    - plot: Run DOA sweep with calibration
    - cal_phase: Perform phase calibration only
    - cal_gain: Perform gain calibration only
    - monopulse_tracking: Real-time monopulse angle tracking with PyQtGraph
"""
import sys
import logging
import numpy as np
from numpy.typing import NDArray
import matplotlib.pyplot as plt
import time
import pyqtgraph as pg
from pyqtgraph.Qt import QtGui
from adrv9009_zu11eg import adrv9009_zu11eg
from typing import Any
import config_talise as config
from talise_calibration_utils import (adjust_gain, do_cal_phase, do_cal_gain,
                                      talise_init, calibrate_boresight,
                                      generate_tx_sinewave)

logger = logging.getLogger(__name__)

# First try to connect to a locally connected Talise. On success, connect,
# on failure, connect to remote Talise
my_talise: adrv9009_zu11eg = adrv9009_zu11eg(uri=config.talise_address)
_, samples = generate_tx_sinewave(windowing=False)

func: str = sys.argv[1] if len(sys.argv) >= 2 else "plot"

if func == "cal_phase":
    logger.info("Calibrating Phase, verbosely, then saving cal file...")
    do_cal_phase(my_talise)
    logger.info("Done Phase Calibration")
elif func == "cal_gain":
    logger.info("Calibrating Gain, verbosely, then saving cal file...")
    do_cal_gain(my_talise)
    logger.info("Done Gain Calibration")
elif func == "plot":
    # Initialize talise
    talise_init(my_talise)
    calibrate_boresight(my_talise)

    # Performing Beamforming
    plt.ion()
    logger.info("Starting, use control-c to stop")
    
    phase_cal: list[float] = [0] + list(my_talise.pcal)
    elem_spacing: float = (3e8 / (config.lo_freq + config.tx_sine_baseband_freq)) / \
                                  config.lambda_over_d_spacing
    signal_freq: float = config.lo_freq
    
    try:
        while True:
            powers: list[float] = []
            angle_of_arrivals: list[float] = []
            
            # Receive samples
            receive_samples: list[NDArray[np.complex128]] = my_talise.rx()
            
            for phase in np.arange(-360 / config.lambda_over_d_spacing,
                                   360 / config.lambda_over_d_spacing,
                                   2
            ):
                rx_samples: list[NDArray[np.complex128]] = list(receive_samples)

                # Apply Gain coefficients
                rx_samples = adjust_gain(my_talise, rx_samples)

                # Apply phase shift using adjust_phase-style logic
                for i in range(my_talise.num_rx_elements):
                    channel_phase: float = ((phase * i) + phase_cal[i]) % 360.0
                    channel_phase_rad: float = np.deg2rad(channel_phase)
                    rx_samples[i] = rx_samples[i] * np.exp(1j * channel_phase_rad)

                steer_angle: np.floating[Any] = np.degrees(
                    np.arcsin(
                        np.clip(
                            (3e8 * np.radians(phase)) / 
                            (2 * np.pi * config.lo_freq * elem_spacing), 
                            -1, 
                            1
                        )
                    )
                )

                angle_of_arrivals.append(steer_angle)
                data_sum: NDArray[np.complex128] = np.sum(rx_samples, axis=0)
                power_dB: float = 10*np.log10(np.sum(np.abs(data_sum)**2))
                powers.append(power_dB)

            powers -= np.max(powers)
            plt.figure(1)
            plt.plot(angle_of_arrivals, powers, '.-')
            plt.xlabel("Angle of Arrival")
            plt.ylabel("Magnitude [dB]")
            plt.grid(True)
            plt.draw()
            plt.pause(0.001)
            plt.clf()
            
    except KeyboardInterrupt:
        sys.exit()

elif func == "monopulse_tracking":
    # Initialize talise
    talise_init(my_talise)
    calibrate_boresight(my_talise)
    my_talise.tx_cyclic_buffer = True
    my_talise.tx(samples)
    
    phase_cal: list[float] = [0] + list(my_talise.pcal)
    elem_spacing: float = (3e8 / (config.lo_freq + config.tx_sine_baseband_freq)) / \
                                  config.lambda_over_d_spacing
    signal_freq: float = config.lo_freq

    powers: list[float] = []
    angle_of_arrivals: list[float] = []
    phase_angles: list[float] = []
    tracking_length: int = 1000
    
    # Receive samples
    receive_samples: list[NDArray[np.complex128]] = my_talise.rx()
    
    for phase in np.arange(-360 / config.lambda_over_d_spacing,
                                360 / config.lambda_over_d_spacing,
                                2
    ):
        rx_samples: list[NDArray[np.complex128]] = list(receive_samples)

        # Apply Gain coefficients
        rx_samples = adjust_gain(my_talise, rx_samples)

        # Set phase difference between the adjacent channels of devices
        for i in range(my_talise.num_rx_elements):
            channel_phase: float = ((phase * i) + phase_cal[i]) % 360.0
            channel_phase_rad: float = np.deg2rad(channel_phase)
            rx_samples[i] = rx_samples[i] * np.exp(1j * channel_phase_rad)

        steer_angle: np.floating[Any] = np.degrees(
                    np.arcsin(
                        np.clip(
                            (3e8 * np.radians(phase)) / 
                            (2 * np.pi * config.lo_freq * elem_spacing), 
                            -1, 
                            1
                        )
                    )
                )
        angle_of_arrivals.append(steer_angle)
        phase_angles.append(phase)
        data_sum: NDArray[np.complex128] = np.sum(rx_samples, axis=0)
        power_dB: float = 10*np.log10(np.sum(np.abs(data_sum)**2))
        powers.append(power_dB)

    powers -= np.max(powers)
    current_phase: float = phase_angles[np.argmax(powers)]
    max_angle: float = angle_of_arrivals[np.argmax(powers)]

    # Now we'll actually update the current_phase based on the error
    phase_log: list[float] = []
    error_log: list[float] = []

    '''Setup Plot Window'''
    # Use pg.mkQApp() for robust application creation
    app = pg.mkQApp("Monopulse Tracking")

    win = pg.GraphicsLayoutWidget(show=True, title="Monopulse Tracking")
    p1 = win.addPlot()
    p1.setXRange(-80,80)
    p1.setYRange(0, tracking_length)
    p1.setLabel('bottom', 'Steering Angle', 'deg', **{'color': '#FFF', 'size': '14pt'})
    p1.showAxis('left', show=False)
    p1.showGrid(x=True, alpha=1)
    p1.setTitle('Monopulse Tracking:  Angle vs Time', **{'color': '#FFF', 'size': '14pt'})
    fn = QtGui.QFont()
    fn.setPointSize(15)
    p1.getAxis("bottom").setTickFont(fn)
    
    delay: float = max_angle
    tracking_angles: NDArray[np.floating] = np.ones(tracking_length)*180
    tracking_angles[:-1] = -180

    curve1 = p1.plot(tracking_angles)
    def update_tracker() -> None:
        global tracking_angles, delay
        global current_phase

        # Now we create the two beams on either side of our current estimate
        receive_samples: list[NDArray[np.complex128]] = my_talise.rx()
        data: list[NDArray[np.complex128]] = list(receive_samples)

        # Apply Gain coefficients
        data = adjust_gain(my_talise, data)

        for i in range(0, 4):
            channel_phase: float = ((current_phase * i) + phase_cal[i]) % 360.0
            channel_phase_rad: float = np.deg2rad(channel_phase)
            data[i] = data[i] * np.exp(1j * channel_phase_rad)

        sum_beam: NDArray[np.complex128] = np.sum(data, axis=0)
        delta_beam: NDArray[np.complex128] = (data[0] + data[1]) - (data[2] + data[3])
        sum_delta_correlation: NDArray[np.complex128] = np.correlate(sum_beam, delta_beam)
        error: NDArray[np.floating] = np.angle(sum_delta_correlation)
        error_log.append(error)

        phase_step: float = 1
        if np.sign(error) > 0:
            current_phase = current_phase - phase_step
        else:
            current_phase = current_phase + phase_step
        steer_angle: np.floating[Any] = np.degrees(
                    np.arcsin(
                        np.clip(
                            (3e8 * np.radians(current_phase)) / 
                            (2 * np.pi * config.lo_freq * elem_spacing), 
                            -1, 
                            1
                        )
                    )
                )
        phase_log.append(steer_angle)

        delay = steer_angle
        tracking_angles = np.append(tracking_angles, delay)
        tracking_angles = tracking_angles[1:]
        curve1.setData(tracking_angles, np.arange(tracking_length))

    timer = pg.QtCore.QTimer()
    timer.timeout.connect(update_tracker)
    timer.start(0)

    ## Start Qt event loop unless running in interactive mode or using pyside.
    if __name__ == '__main__':
        if (sys.flags.interactive != 1):
            sys.exit(app.exec())

else:
    logger.warning("When calling talise_example.py add one argument between: plot, cal_phase, cal_gain, monopulse_tracking")

