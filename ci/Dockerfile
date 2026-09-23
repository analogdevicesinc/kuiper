FROM scratch
ADD kuiper_image.tar /
CMD ["/bin/bash"]

ENV DEBIAN_FRONTEND=noninteractive

RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt update
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y build-essential git wget sudo
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y libxml2-dev bison flex libcdk5-dev cmake
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y libaio-dev libusb-1.0-0-dev libzstd-dev
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y libserialport-dev libavahi-client-dev
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y doxygen graphviz man2html
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y wget curl tar
RUN DEBIAN_FRONTEND=$DEBIAN_FRONTEND apt-get install -y python3 python3-pip python3-setuptools python3-full

RUN pip3 install sphinx sphinx_rtd_theme furo

# Cleanup
RUN apt-get clean
