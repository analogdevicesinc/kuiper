"""
This configuration file sets up the network parameters and hardware-specific settings for the
Talise (ADRV9009-ZU11EG) SDR device used in the system. Key parameters are specified such as
transmit frequency, amplitude and gain values for each channel as well as phased array antenna
(used on Rx channels) parameters such as the distance between each antenna element
relative to wavelength.
"""

# Change for different applications
talise_address:str = "ip:10.48.65.199"  # add ip of talise
lo_freq:int = 5400000000 - 300000 # [Hz] LO frequency of talise
tx_sine_baseband_freq:int = 300000 # [Hz] Sine frequency transmitted
amplitude_discrete:int = 2**16 # Discrete amplitude of transmitted samples
number_periods_sine_baseband:int = 12
lambda_over_d_spacing:float = 1.93 # for Rx phased array antenna
onboard_tx1_used:bool = True
tx_channels_used: list[int] = [1] # Channels used to transmit
rx_gain_control_mode:str = "manual"
rx_gain:int = 30
tx_gain:int =  0 if onboard_tx1_used else -40
tx_unused_channel_gain:int = -30 # Very low gain on unused Tx channels

# The following variables are set automatically and should not be modified
rx_channels_used: list[int] = [0, 1, 2, 3]
used_rx_channels:int = len(rx_channels_used)
sample_rate:int = 245760000 # [Hz] sample rate of talise
# Calculated number of samples per buffer
num_samps:int = int((number_periods_sine_baseband * sample_rate) / tx_sine_baseband_freq)
tx_buffer_size:int = num_samps # Buffer size for one Tx transmission
rx_buffer_size:int = num_samps # Buffer size for one Rx capture 
