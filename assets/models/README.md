# TensorFlow Lite Model Files

## Required Files

Place your trained TensorFlow Lite model in this directory:

- **detect.tflite** - Your trained object detection model
- **labels.txt** - Class labels (already provided)

## Model Specifications

### Input

- Size: 320x320 or 416x416 pixels
- Format: RGB normalized [0, 1]
- Shape: [1, height, width, 3]

### Output

- Format: [1, num_detections, 5 + num_classes]
- Values: [x, y, w, h, confidence, class_scores...]

### Supported Models

1. **YOLOv5/YOLOv8 TFLite**
   - Fast and accurate
   - Good for mobile deployment
   - Export from PyTorch: `model.export(format='tflite')`

2. **SSD MobileNet**
   - Optimized for mobile
   - Lower computational requirements
   - Available from TensorFlow Model Zoo

3. **Custom Trained Models**
   - Use TensorFlow Lite Model Maker
   - Train on your telescope images
   - Export to TFLite format

## Getting a Pre-trained Model

### Option 1: Use TensorFlow Model Zoo

Download SSD MobileNet V2:

```bash
wget https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip
unzip coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip
mv detect.tflite assets/models/
```

### Option 2: Train Custom Model

Use Google Teachable Machine or TensorFlow Lite Model Maker:

1. Collect images of Moon and planets from your telescope
2. Label them with bounding boxes
3. Train using transfer learning
4. Export to TFLite format
5. Place in this directory

### Option 3: Convert Existing Model

If you have a PyTorch YOLO model:

```python
from ultralytics import YOLO

# Load model
model = YOLO('yolov8n.pt')

# Export to TFLite
model.export(format='tflite', imgsz=320)
```

## Labels

The `labels.txt` file contains the object classes:

- Line 0: Moon
- Line 1: Jupiter
- Line 2: Saturn
- Line 3: Venus
- Line 4: Mars

Each line corresponds to a class index in the model output.

## Testing Your Model

Use the AI Detection screen in the app:

1. Place your model in this directory
2. Launch the app
3. Navigate to AI Detection
4. Point camera at test images
5. Verify detections

## Model Performance

Target specifications:

- Inference time: < 200ms per frame
- FPS: 5-15 on mid-range device
- Accuracy: > 80% on test set
- Model size: < 50MB

## Resources

- [TensorFlow Lite Guide](https://www.tensorflow.org/lite)
- [YOLOv5 TFLite Export](https://github.com/ultralytics/yolov5)
- [TensorFlow Model Maker](https://www.tensorflow.org/lite/models/modify/model_maker)
- [Pre-trained Models](https://www.tensorflow.org/lite/guide/hosted_models)

## Notes

⚠️ The model file is **not included** in this repository due to size constraints.
You must provide your own trained model or download a pre-trained one.

For astronomical object detection, training a custom model is highly recommended
as standard models (trained on COCO dataset) may not recognize celestial bodies accurately.
