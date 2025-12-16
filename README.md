
# Docker OpenCV + FFmpeg + CUDA Builder

A **from-source Docker builder image** for  **GPU-accelerated OpenCV and FFmpeg** , compiled with **CUDA, cuDNN, NPP, NVENC, and NVDEC** support.

This repository provides a **reproducible, production-grade Dockerfile** to build:

* **CUDA-enabled OpenCV 4.12.0**
* **FFmpeg 7.x with NVENC / NVDEC / CUVID**
* **Python 3.12**
* **Ubuntu 24.04**
* **CUDA 12.8.1 + cuDNN**

Designed for  **computer vision** ,  **video processing** , and  **GPU-accelerated pipelines** .

---

## 🚀 Features

### OpenCV (Built from Source)

* CUDA acceleration enabled
* cuDNN support
* NVIDIA NPP support
* OpenCV DNN CUDA backend
* FFmpeg integration
* TBB + OpenGL support
* Python 3 bindings

### FFmpeg (Built from Source)

* CUDA hardware acceleration
* NVENC (H.264 / HEVC / AV1)
* NVDEC / CUVID decoders
* NVIDIA NPP support
* libx264, libx265, libvpx
* libfdk-aac, mp3, opus, vorbis

### Platform

* Ubuntu 24.04
* CUDA 12.8.1
* cuDNN enabled
* Python 3.12

---

## 📦 Base Image

```
nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
```

---

## 🧰 Requirements

* Docker 20.10+
* NVIDIA GPU (Pascal or newer recommended)
* NVIDIA driver compatible with CUDA 12.8
* NVIDIA Container Toolkit

### Install NVIDIA Container Toolkit

```bash
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

---

## 🔨 Build the Image

```bash
docker build -t cuda-opencv-ffmpeg .
```

> ⚠️ Build time is long (30–90 minutes) due to full source compilation.

---

## ▶️ Run the Container

```bash
docker run --rm -it --gpus all cuda-opencv-ffmpeg bash
```

---

## ✅ Verify OpenCV CUDA Support

```bash
docker run --rm --gpus all -i cuda-opencv-ffmpeg \
  python <<'EOF'
import cv2
print("OpenCV:", cv2.__version__)
print("CUDA devices:", cv2.cuda.getCudaEnabledDeviceCount())
EOF
```

Expected:

```
OpenCV: 4.12.0
CUDA devices: 1
```

---

## ✅ Verify OpenCV CUDA Kernel Execution

This confirms  **actual GPU execution** , not just build flags.

```bash
docker run --rm --gpus all -i cuda-opencv-ffmpeg \
  python <<'EOF'
import cv2, numpy as np

img = np.random.randint(0,256,(720,1280,3),dtype=np.uint8)
gpu = cv2.cuda_GpuMat()
gpu.upload(img)
gray = cv2.cuda.cvtColor(gpu, cv2.COLOR_BGR2GRAY)

print("CUDA kernel executed:", gray.download().shape)
EOF
```

---

## 🎥 Verify FFmpeg GPU Support

### Check CUDA Hardware Acceleration

```bash
docker run --rm --gpus all cuda-opencv-ffmpeg ffmpeg -hwaccels
```

Expected:

```
cuda
```

### Check NVENC Encoders

```bash
docker run --rm --gpus all cuda-opencv-ffmpeg \
  ffmpeg -encoders | grep nvenc
```

### Check NVDEC / CUVID Decoders

```bash
docker run --rm --gpus all cuda-opencv-ffmpeg \
  ffmpeg -decoders | grep cuvid
```

---

## 🚀 Real GPU Encode Test

```bash
docker run --rm --gpus all -v $(pwd):/data cuda-opencv-ffmpeg \
  ffmpeg -y -hwaccel cuda -i /data/input.mp4 \
         -c:v h264_nvenc -preset p3 /data/output.mp4
```

---

## 🧠 Supported GPU Architectures

The image is built with support for:

```
6.1  7.0  7.5  8.0  8.6  8.7  8.9  9.0  10.0  12.0
```

Covers:

* GTX 10xx
* RTX 20xx / 30xx / 40xx
* NVIDIA A-series (A10, A100, etc.)
* Hopper-class GPUs

---

## 📁 Repository Structure

```
.
├── Dockerfile
├── README.md
└── main.py (optional user application)
```

---

## ⚠️ Notes

* This is a **builder-style image** (large size)
* Ideal for:
  * Development
  * CI pipelines
  * GPU servers
* For deployment, consider a **multi-stage runtime image**

---

## 🔮 Roadmap (Optional Enhancements)

* Multi-stage runtime-only image
* Buildx / multi-arch support
* OpenCV + FFmpeg zero-copy CUDA pipeline
* Performance benchmarks (CPU vs GPU)

---

## 👤 Maintainer

**Vishva Ram**
GitHub: [https://github.com/vishvaRam](https://github.com/vishvaRam)
Docker Hub: [https://hub.docker.com/u/vishva123](https://hub.docker.com/u/vishva123)

---

## 📜 License

This project follows the licenses of:

* OpenCV
* FFmpeg
* NVIDIA CUDA & cuDNN

Please review upstream licenses before commercial use.
