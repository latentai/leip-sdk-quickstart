#!/bin/bash

set -e

echo "Setting up TVM logs"
git clone https://github.com/tlc-pack/tophub.git
mkdir -p ~/.tvm/tophub
cp tophub/tophub/* ~/.tvm/tophub
rm -rf tophub

echo "Installing Python packages for LEIP Optimize..."
pip install \
  torch \
  torchvision \
  "numpy~=1.24" \
  ultralytics \
  kagglehub \
  tflite \
  huggingface_hub \
  colorama \
  optimum[onnx] \
  timm

echo "Downloading models and datasets..."
python3 << 'EOF'
import os
import urllib.request
import zipfile
import torch
from optimum.exporters.onnx import main_export
from ultralytics import YOLO

PARENT_DIR = "/latentai/leip-optimize/notebooks"
os.chdir(PARENT_DIR)

os.makedirs("models", exist_ok=True)

print("Downloading COCO val2017 dataset...")
url = "http://images.cocodataset.org/zips/val2017.zip"
file_path = "val2017.zip"
urllib.request.urlretrieve(url, file_path)

print("Extracting...")
with zipfile.ZipFile(file_path, 'r') as zip_ref:
    zip_ref.extractall(".")
os.remove(file_path)

print("Downloading DETR model...")
main_export(
    model_name_or_path="facebook/detr-resnet-50",
    output="/latentai/leip-optimize/notebooks/models/detr_resnet50",
    task="object-detection",
    opset=12,
    device="cpu"
)

print("Downloading ResNet-50 model...")
main_export(
    model_name_or_path="microsoft/resnet-50",
    output="/latentai/leip-optimize/notebooks/models/resnet-50",
    task="image-classification",
    no_dynamic_axes=True,
    opset=12,
    device="cpu"
)

print("Downloading YOLOv8 model...")
model = YOLO("/latentai/leip-optimize/notebooks/models/yolov8n.pt")
model.model.eval()
model.model(torch.randn(1, 3, 640, 640))

torch.onnx.export(
    model.model,
    torch.randn([1, 3, 640, 640]),
    "/latentai/leip-optimize/notebooks/models/yolov8n.onnx",
    do_constant_folding=True,
    input_names=["images"],
    output_names=["output0"]
)

print("Done!")
EOF

echo "LEIP Optimize setup complete!"