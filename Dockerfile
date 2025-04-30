FROM osrf/ros:jazzy-desktop-full
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to Taiwan
RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config

############################### INSTALL #######################################
# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
        # * Shell
        sudo \
        git \
        htop \
        wget \
        curl \
        psmisc \
        # * base tools
        tmux \
        terminator \
        # * Work tools
        udev \
        libtool \
        python3-pip \
        python3-dev \
        python3-setuptools \
        python3-colcon-common-extensions \
        software-properties-common \
        lsb-release \
        # Editing tools
        nano vim gedit \
        gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*


# RUN ./config/pip/pip_setup.sh

############################## USER CONFIG ####################################


RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN echo 'export CXX=g++' >> ~/.bashrc \
    && echo 'export MAKEFLAGS="-j$(nproc)"' >> ~/.bashrc \
    && echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc \
    && echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc \
    && echo "source ~/work/install/setup.bash" >> ~/.bashrc
# RUN export CXX=g++
# RUN export MAKEFLAGS="-j nproc"
# RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
# RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc


# * Switch workspace to ~/work
WORKDIR /home/"${USER}"/work
RUN echo "source ~/work/install/setup.bash"  >> ~/.bashrc

# * Switch user to ${USER}
USER ${USER}
# * Make SSH available
EXPOSE 22

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
