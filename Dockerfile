FROM osrf/ros:jazzy-desktop-full
SHELL ["/bin/bash", "-c"]

############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=ron
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# * Setup users and groups
    RUN set -eux; \
    if ! getent group "${GROUP}" >/dev/null; then \
        groupadd "${GROUP}"; \
    fi; \
    if ! id -u "${USER}" >/dev/null 2>&1; then \
        useradd -ms "${SHELL}" -g "${GROUP}" "${USER}"; \
    fi; \
    mkdir -p /etc/sudoers.d; \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}"; \
    chmod 0440 "/etc/sudoers.d/${USER}"

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
        # * pip
        python3-pip \
        python3-dev \
        python3-setuptools \
        python3-colcon-common-extensions \
        # Editing tools
        nano vim gedit \
        gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt update \
    && apt install -y --no-install-recommends \
        # pip setup
        python3-venv \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN ./config/pip/pip_setup.sh

############################## USER CONFIG ####################################
# * Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN echo 'export CXX=g++' >> ~/.bashrc \
    && echo 'export MAKEFLAGS="-j$(nproc)"' >> ~/.bashrc \
    && echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc \
    && echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc \
    && echo "source ~/work/install/setup.bash" >> ~/.bashrc

# * Switch workspace to ~/work
WORKDIR /home/"${USER}"/work
RUN echo "source ~/work/install/setup.bash"  >> ~/.bashrc

# * Make SSH available
EXPOSE 22

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
