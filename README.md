# [VoxelMAP](https://github.com/hku-mars/VoxelMap/) converter to [HDMapping](https://github.com/MapsHD/HDMapping)

## Hint

Please change branch to [Bunker-DVI-Dataset-reg-1](https://github.com/MapsHD/benchmark-VoxelMap-to-HDMapping/tree/Bunker-DVI-Dataset-reg-1) for quick experiment.  

## Intended use 

This small toolset allows to integrate SLAM solution provided by [VoxelMap](https://github.com/hku-mars/VoxelMap/) with [HDMapping](https://github.com/MapsHD/HDMapping).
This repository contains ROS 1 workspace that :
  - submodule to tested revision of VoxelMap
  - a converter that listens to topics advertised from odometry node and save data in format compatible with HDMapping.

## Dependencies

```shell
sudo apt install -y nlohmann-json3-dev
```

## Building

Clone the repo
```shell
mkdir -p /test_ws/src
cd /test_ws/src
git clone https://github.com/MapsHD/benchmark-VoxelMap-to-HDMapping.git --recursive
cd ..
catkin_make
```

## Usage - data SLAM:

Prepare recorded bag with estimated odometry:

In first terminal record bag:
```shell
rosbag record /cloud_registered /aft_mapped_to_init
```

and start odometry:
```shell 
cd /test_ws/
source ./devel/setup.sh # adjust to used shell
roslaunch voxel_map mapping_velodyne.launch
rosbag play *.bag --clock
```

## Usage - conversion:

```shell
cd /test_ws/
source ./devel/setup.sh # adjust to used shell
rosrun voxel-to-hdmapping listener <recorded_bag> <output_dir>
```

## Record the bag file:

```shell
rosbag record /cloud_registered /aft_mapped_to_init
```

## VoxelMap Launch:

```shell
cd /test_ws/
source ./install/setup.sh # adjust to used shell
roslaunch voxel_map mapping_velodyne.launch
rosbag play {path_to_bag} --clock pp_points/synced2rgb:=/velodyne_points
```

## During the record (if you want to stop recording earlier) / after finishing the bag:

```shell
In the terminal where the ros record is, interrupt the recording by CTRL+C
Do it also in ros launch terminal by CTRL+C.
```

## Usage - Conversion (ROS bag to HDMapping, after recording stops):

```shell
cd /test_ws/
source ./install/setup.sh # adjust to used shell
rosrun voxel-to-hdmapping listener <recorded_bag> <output_dir>
```
