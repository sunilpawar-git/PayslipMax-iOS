#!/usr/bin/env python3
"""
EdgeTPU to CPU TensorFlow Lite Model Converter
Converts EdgeTPU-compiled models to iOS-compatible CPU models
"""

import os
import sys
import tensorflow as tf
from pathlib import Path

def check_model_compatibility(model_path):
    """Check if model has EdgeTPU custom ops"""
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        print(f"✅ {model_path} - CPU compatible")
        return True
    except Exception as e:
        if "edgetpu-custom-op" in str(e):
            print(f"❌ {model_path} - EdgeTPU incompatible: {e}")
            return False
        else:
            print(f"⚠️ {model_path} - Other error: {e}")
            return False

def convert_model_from_saved_model(saved_model_dir, output_path):
    """Convert SavedModel to CPU-compatible TensorFlow Lite"""
    try:
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
        
        # CPU-only optimizations
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,  # Standard TFLite ops
            tf.lite.OpsSet.SELECT_TF_OPS     # TensorFlow ops fallback
        ]
        
        # Disable EdgeTPU compilation
        converter.experimental_new_converter = True
        converter.allow_custom_ops = False
        
        # Convert
        tflite_model = converter.convert()
        
        # Save
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
            
        print(f"✅ Converted: {output_path}")
        return True
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return False

def main():
    models_dir = Path("PayslipMax/Resources/Models")
    backup_dir = Path("PayslipMax/Resources/Models/EdgeTPU_Backup")
    
    # Create backup directory
    backup_dir.mkdir(exist_ok=True)
    
    # Model conversion mapping
    models_to_convert = {
        "table_detection.tflite": "table_detection_cpu.tflite",
        "text_recognition.tflite": "text_recognition_cpu.tflite", 
        "document_classifier.tflite": "document_classifier_cpu.tflite",
        "financial_data_validator.tflite": "financial_data_validator_cpu.tflite",
        "pp_ocr_v3.tflite": "pp_ocr_v3_cpu.tflite",
        "pp_structure_v2.tflite": "pp_structure_v2_cpu.tflite"
    }
    
    print("🔍 Checking model compatibility...")
    
    for original_name, cpu_name in models_to_convert.items():
        original_path = models_dir / original_name
        
        if not original_path.exists():
            print(f"⚠️ Model not found: {original_path}")
            continue
            
        # Check current compatibility
        is_compatible = check_model_compatibility(str(original_path))
        
        if not is_compatible:
            print(f"🔄 Converting {original_name}...")
            
            # Backup original
            backup_path = backup_dir / original_name
            if not backup_path.exists():
                import shutil
                shutil.copy2(original_path, backup_path)
                print(f"📁 Backed up to: {backup_path}")
            
            # Convert to CPU version
            cpu_path = models_dir / cpu_name
            
            # For now, we'll need the original SavedModel sources
            # This is a placeholder - you'll need to provide SavedModel directories
            print(f"⚠️ Need SavedModel source for {original_name}")
            print(f"   Place SavedModel in ModelDownloads/saved_models/{original_name.stem}/")

if __name__ == "__main__":
    main()
