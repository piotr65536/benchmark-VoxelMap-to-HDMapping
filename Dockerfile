FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 lsb-release software-properties-common sudo \
    build-essential git cmake \
    python3-pip \
    libceres-dev libeigen3-dev \
    libpcl-dev \
    nlohmann-json3-dev \
    libusb-1.0-0-dev \
    tmux \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ros1.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone https://github.com/Livox-SDK/Livox-SDK.git && \
    cd Livox-SDK && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install

WORKDIR /ws_livox

RUN mkdir -p src

WORKDIR /ws_livox/src

RUN git clone https://github.com/Livox-SDK/livox_ros_driver.git

WORKDIR /ws_livox

RUN source /opt/ros/noetic/setup.bash && \
    catkin_make

WORKDIR /ros_ws

COPY ./src ./src

RUN sed -i \
    -e 's|lid_topic:.*|lid_topic:  "/livox/lidar"|' \
    -e 's|imu_topic:.*|imu_topic:  "/livox/imu"|' \
    -e 's|lidar_type:.*|lidar_type: 1|' \
    -e 's/pub_voxel_map:.*/pub_voxel_map: true/' \
    -e 's/pub_point_cloud:.*/pub_point_cloud: true/' \
    -e 's/dense_map_enable:.*/dense_map_enable: true/' \
    src/VoxelMap/config/velodyne.yaml

# VoxelMap stamps its outputs with ros::Time::now(). The run script replays the
# bag with the clock option and passes use_sim_time:=true, but the upstream
# launch file never declares that argument, so roslaunch ignores it. The
# trajectory then carries wall-clock stamps that share no timestamps with the
# ground truth, and the benchmark row comes out empty. Declare the argument and
# map it onto the /use_sim_time parameter. The grep fails the build if the
# upstream launch file stops matching.
RUN LAUNCH=src/VoxelMap/launch/mapping_velodyne.launch && \
    sed -i 's|<launch>|<launch>\n    <arg name="use_sim_time" default="false" />\n    <param name="/use_sim_time" type="bool" value="$(arg use_sim_time)" />|' "$LAUNCH" && \
    grep -q 'name="/use_sim_time"' "$LAUNCH"

# src/ contains its own copy of livox_ros_driver, which takes precedence over
# /ws_livox, and VoxelMap includes the livox_ros_driver/CustomMsg.h it
# generates. In one parallel catkin_make, VoxelMap can compile before that
# header exists ("fatal error: livox_ros_driver/CustomMsg.h: No such file or
# directory"), which happens on machines with many cores. Build the driver
# first, the same way the C3P-VoxelMap benchmark does.
RUN source /opt/ros/noetic/setup.bash && \
    source /ws_livox/devel/setup.bash && \
    catkin_make --pkg livox_ros_driver && \
    catkin_make
    
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros
    
WORKDIR /ros_ws

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && \
    echo "source /ws_livox/devel/setup.bash" && >> ~/.bashrc \
    echo "source /ros_ws/devel/setup.bash" >> ~/.bashrc

CMD ["bash"]