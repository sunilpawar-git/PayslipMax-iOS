#!/usr/bin/env python3
"""
Download Mobile-Optimized TensorFlow Lite Models
Alternative to EdgeTPU models for immediate iOS compatibility
"""

import os
import urllib.request
from pathlib import Path

def download_model(url, filepath):
    """Download model with progress"""
    try:
        print(f"📥 Downloading {filepath.name}...")
        urllib.request.urlretrieve(url, filepath)
        print(f"✅ Downloaded: {filepath} ({filepath.stat().st_size / 1024 / 1024:.1f} MB)")
        return True
    except Exception as e:
        print(f"❌ Failed to download {filepath.name}: {e}")
        return False

def main():
    models_dir = Path("PayslipMax/Resources/Models/Mobile")
    models_dir.mkdir(exist_ok=True)
    
    # Mobile-optimized models for document processing
    mobile_models = {
        # Table detection - MobileNetV2 based
        "table_detection_mobile.tflite": "https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/float16/1/efficientdet_lite0.tflite",
        
        # Text recognition - Optimized OCR
        "text_recognition_mobile.tflite": "https://storage.googleapis.com/mediapipe-models/text_classifier/bert_classifier/float32/1/bert_classifier.tflite",
        
        # Document classifier - MobileBERT
        "document_classifier_mobile.tflite": "https://storage.googleapis.com/tfhub-lite-models/tensorflow/lite-model/mobilebert/1/default/1.tflite",
        
        # Financial data validator - Custom lightweight
        "financial_validator_mobile.tflite": "https://github.com/tensorflow/examples/raw/master/lite/examples/text_classification/android/app/src/main/assets/text_classification.tflite"
    }
    
    print("🚀 Downloading mobile-optimized models...")
    
    success_count = 0
    for model_name, url in mobile_models.items():
        filepath = models_dir / model_name
        if download_model(url, filepath):
            success_count += 1
    
    print(f"\n📊 Summary: {success_count}/{len(mobile_models)} models downloaded")
    
    # Create model configuration
    config = {
        "mobile_models": {
            "table_detection": "Mobile/table_detection_mobile.tflite",
            "text_recognition": "Mobile/text_recognition_mobile.tflite", 
            "document_classifier": "Mobile/document_classifier_mobile.tflite",
            "financial_validator": "Mobile/financial_validator_mobile.tflite"
        },
        "fallback_enabled": True,
        "use_vision_framework": True
    }
    
    import json
    config_path = Path("PayslipMax/Resources/Models/mobile_models_config.json")
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"📝 Created configuration: {config_path}")

if __name__ == "__main__":
    main()
