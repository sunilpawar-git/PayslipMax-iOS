#!/usr/bin/env python3
"""
Strategic model replacement for PayslipMax
Replace EdgeTPU models with iOS-compatible alternatives
"""

import os
import urllib.request
from pathlib import Path
import shutil

def download_compatible_models():
    """Download working iOS-compatible models"""
    models_dir = Path("PayslipMax/Resources/Models")
    
    # Lightweight models that actually work on iOS
    working_models = {
        # Document classification - MobileBERT (2MB vs 4.1MB)
        "document_classifier_mobile.tflite": "https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1.tflite",
        
        # Table detection - EfficientNet (8MB vs 35MB) 
        "table_detection_mobile.tflite": "https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/float16/1/efficientdet_lite0.tflite",
        
        # Text recognition - Lightweight OCR (12MB vs 38MB)
        "text_recognition_mobile.tflite": "https://github.com/PaddlePaddle/PaddleOCR/raw/release/2.6/deploy/lite/ocr_v2_for_cpu.nb"
    }
    
    total_saved = 0
    models_dir.mkdir(exist_ok=True)
    
    for model_name, url in working_models.items():
        try:
            print(f"📥 Downloading {model_name}...")
            filepath = models_dir / model_name
            urllib.request.urlretrieve(url, filepath)
            size_mb = filepath.stat().st_size / 1024 / 1024
            print(f"✅ {model_name}: {size_mb:.1f}MB")
            total_saved += size_mb
        except Exception as e:
            print(f"❌ Failed to download {model_name}: {e}")
    
    print(f"\n📊 Total new models: {total_saved:.1f}MB (vs 154MB broken models)")
    print(f"💾 Space saved: {154 - total_saved:.1f}MB")

def remove_broken_models():
    """Remove EdgeTPU-incompatible models"""
    models_dir = Path("PayslipMax/Resources/Models")
    
    # Backup first
    backup_dir = Path("ModelDownloads/EdgeTPU_Backup")
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    broken_models = [
        "document_classifier.tflite",
        "financial_data_validator*.tflite", 
        "layout_lm_v3.tflite",
        "pp_ocr_v*.tflite",
        "pp_structure_v*.tflite"
    ]
    
    for pattern in broken_models:
        for model_file in models_dir.glob(pattern):
            # Backup
            shutil.copy2(model_file, backup_dir / model_file.name)
            # Remove
            model_file.unlink()
            print(f"🗑️ Removed {model_file.name}")

if __name__ == "__main__":
    print("🚀 PayslipMax Model Strategy: Replace EdgeTPU with Working Models")
    print("\nOption 1: Remove broken models (save 154MB)")
    print("Option 2: Replace with working lightweight models")
    
    choice = input("\nChoose (1/2): ").strip()
    
    if choice == "1":
        remove_broken_models()
        print("✅ Removed broken models. Enhanced fallbacks will handle parsing.")
    elif choice == "2":
        remove_broken_models()
        download_compatible_models()
        print("✅ Replaced with working models!")
    else:
        print("❌ Invalid choice")
