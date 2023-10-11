FROM ubuntu:20.04

# Install basic dependencies
RUN set -xe \
	&& apt-get update -y \
	&& apt-get install -y curl gnupg2 wget

# Install Python 3.10
RUN apt-get install software-properties-common -y \
	&& add-apt-repository ppa:deadsnakes/ppa -y \
	&& apt-get install -y python3.10 \
	&& apt-get install -y python3.10-dev

RUN apt-get install -y \
	build-essential \
	manpages-dev \
	software-properties-common

RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt-get update \
	&& apt-get install -y gcc-11 g++-11

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.10 get-pip.py

ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="3.5 5.0 6.0 6.1 7.0 7.5 8.0 8.6"

# # Install CUDA 11.6 Toolkit
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
RUN mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN wget https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda-repo-wsl-ubuntu-11-6-local_11.6.0-1_amd64.deb
RUN dpkg -i cuda-repo-wsl-ubuntu-11-6-local_11.6.0-1_amd64.deb
RUN apt-key add /var/cuda-repo-wsl-ubuntu-11-6-local/7fa2af80.pub
RUN apt-get update
RUN apt-get -y install cuda-toolkit-11-6
RUN apt-get -y install cuda

# Install NVIDIA's container toolkit
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
	tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  && \
	apt-get update
RUN apt-get install -y libpq-dev build-essential nvidia-container-toolkit

# Create workspace
WORKDIR /workspace
COPY ./requirements.txt ./
COPY ./submodules ./submodules

# Install Gaussian Splatting Requirements
RUN python3.10 -m pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu116
RUN python3.10 -m pip install plyfile==0.8.1 tqdm cmake submodules/diff-gaussian-rasterization submodules/simple-knn


# RUN python3.10 -m pip install --no-cache-dir -r requirements.txt
# RUN python3.10 -m pip install --no-cache-dir submodules/diff-gaussian-rasterization submodules/simple-knn

# # Tweak the CMake file for matching the existing OpenCV version. Fix the naming of FindEmbree.cmake
# # WORKDIR /workspace/gaussian-splatting/SIBR_viewers/cmake/linux
# # RUN sed -i 's/find_package(OpenCV 4\.5 REQUIRED)/find_package(OpenCV 4.2 REQUIRED)/g' dependencies.cmake
# # RUN sed -i 's/find_package(embree 3\.0 )/find_package(EMBREE)/g' dependencies.cmake
# # RUN mv /workspace/gaussian-splatting/SIBR_viewers/cmake/linux/Modules/FindEmbree.cmake /workspace/gaussian-splatting/SIBR_viewers/cmake/linux/Modules/FindEMBREE.cmake

# # Fix the naming of the embree library in the rayscaster's cmake
# # RUN sed -i 's/\bembree\b/embree3/g' /workspace/gaussian-splatting/SIBR_viewers/src/core/raycaster/CMakeLists.txt

# # Ready to build the viewer now.
# # WORKDIR /workspace/gaussian-splatting/SIBR_viewers
# # RUN cmake -Bbuild . -DCMAKE_BUILD_TYPE=Release && \
# #     cmake --build build -j24 --target install
# # CMD ["python3", "train.py -s ./workspace/bicycle/input.ply --eval"]