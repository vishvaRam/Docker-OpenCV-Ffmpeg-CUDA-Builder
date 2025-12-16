# Use NVIDIA CUDA base image with cuDNN
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Set environment variables to disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Set the working directory
WORKDIR /app

# Install system dependencies including FFmpeg build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    curl \
    wget \
    build-essential \
    cmake \
    gcc \
    g++ \
    pkg-config \
    yasm \
    nasm \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libtbb12 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libdc1394-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libx265-dev \
    libvpx-dev \
    libass-dev \
    libfreetype6-dev \
    libmp3lame-dev \
    libopus-dev \
    libvorbis-dev \
    libfdk-aac-dev \
    libssl-dev \
    libatlas-base-dev \
    gfortran \
    python3.12 \
    python3-dev \
    python3-venv \
    python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create symlink to make "python" command available
RUN ln -sf /usr/bin/python3.12 /usr/bin/python

# Install numpy first (required for OpenCV Python bindings)
RUN pip install --no-cache-dir --break-system-packages numpy==1.26.4

# Download and install NVIDIA codec headers for FFmpeg
WORKDIR /tmp
RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    git checkout n12.2.72.0 && \
    make install && \
    cd .. && rm -rf nv-codec-headers

# Download and compile FFmpeg with CUDA support (using GitHub mirror)
RUN git clone --depth 1 --branch release/7.1 https://github.com/FFmpeg/FFmpeg.git /tmp/ffmpeg

WORKDIR /tmp/ffmpeg

RUN ./configure \
    --prefix=/usr/local \
    --enable-nonfree \
    --enable-gpl \
    --enable-version3 \
    --enable-cuda-nvcc \
    --enable-cuvid \
    --enable-nvenc \
    --enable-nvdec \
    --enable-libnpp \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-openssl \
    --enable-shared

# Compile and install FFmpeg
RUN make -j$(nproc) && make install && ldconfig

# Now clone OpenCV and OpenCV contrib
WORKDIR /app

RUN git clone --branch 4.12.0 --depth 1 https://github.com/opencv/opencv.git && \
    git clone --branch 4.12.0 --depth 1 https://github.com/opencv/opencv_contrib.git

# Create a build directory for OpenCV
WORKDIR /app/opencv/build

# Configure OpenCV with CUDA support and custom FFmpeg
RUN cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=/app/opencv_contrib/modules \
    -D WITH_CUDA=ON \
    -D ENABLE_FAST_MATH=ON \
    -D CUDA_FAST_MATH=ON \
    -D WITH_CUBLAS=ON \
    -D OPENCV_DNN_CUDA=ON \
    -D WITH_CUDNN=ON \
    -D CUDA_ARCH_BIN="6.1 7.0 7.5 8.0 8.6 8.7 8.9 9.0 10.0 12.0" \
    -D CUDA_ARCH_PTX="12.0" \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_opencv_python3=ON \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D WITH_TBB=ON \
    -D WITH_V4L=ON \
    -D WITH_OPENGL=ON \
    -D WITH_FFMPEG=ON \
    -D OPENCV_FFMPEG_USE_FIND_PACKAGE=ON ..

# Compile and install OpenCV
RUN make -j$(nproc) && make install && ldconfig

# Clean up build artifacts to reduce image size
WORKDIR /app
RUN rm -rf /tmp/ffmpeg /app/opencv /app/opencv_contrib

# Install ONLY ffmpeg-python (NOT opencv-python-headless)
RUN pip install --no-cache-dir --break-system-packages ffmpeg-python

# Copy application code
COPY . /app

# Set the working directory
WORKDIR /app

# Verify installations
RUN python -c "import cv2; print('OpenCV version:', cv2.__version__); print('CUDA enabled:', cv2.cuda.getCudaEnabledDeviceCount() > 0)" && \
    python -c "import cv2; print('FFmpeg support:', 'YES' if any('FFMPEG' in line and 'YES' in line for line in cv2.getBuildInformation().split('\n')) else 'NO')" && \
    ffmpeg -version && \
    ffmpeg -encoders | grep nvenc

# Set default command
CMD ["python", "main.py"]
