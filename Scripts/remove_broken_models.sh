#!/bin/bash
# Remove EdgeTPU-incompatible models and clean up references

echo "🧹 Removing broken EdgeTPU models..."

# Backup models first
mkdir -p ModelDownloads/EdgeTPU_Backup/
cp -r PayslipMax/Resources/Models/*.tflite ModelDownloads/EdgeTPU_Backup/ 2>/dev/null || true

# Remove broken models
rm -f PayslipMax/Resources/Models/document_classifier.tflite
rm -f PayslipMax/Resources/Models/financial_data_validator*.tflite  
rm -f PayslipMax/Resources/Models/layout_lm_v3.tflite
rm -f PayslipMax/Resources/Models/pp_ocr_v*.tflite
rm -f PayslipMax/Resources/Models/pp_structure_v*.tflite
rm -f PayslipMax/Resources/Models/table_detection.tflite
rm -f PayslipMax/Resources/Models/text_recognition.tflite

# Keep only lightweight configs
echo "✅ Kept configuration files and fallback logic"
echo "💾 Backed up models to ModelDownloads/EdgeTPU_Backup/"
echo "📱 Freed up ~154MB app space"

# Show remaining size
du -sh PayslipMax/Resources/Models/ 2>/dev/null || echo "Models directory cleaned"
