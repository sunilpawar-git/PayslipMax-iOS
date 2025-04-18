#!/usr/bin/env swift

import Foundation

// Check if the script is running with arguments
if CommandLine.arguments.count > 1 {
    // Forward all arguments to the BenchmarkTool
    BenchmarkTool.main()
} else {
    // If no arguments, print usage information
    print("""
    📊 PayslipMax Benchmark Tool 📊
    
    Usage:
      ./benchmark.swift [command] [options]
    
    Commands:
      comprehensive [pdf_path]    Run a comprehensive benchmark of all extraction methods
      presets [pdf_path]          Benchmark all extraction presets
      custom [pdf_path]           Run benchmark with custom extraction options
    
    Options:
      For 'comprehensive' and 'presets':
        --save-results, -s        Save results to a CSV file
      
      For 'custom':
        --parallel                Use parallel processing (true/false)
        --preprocess              Preprocess text (true/false)
        --adaptive-batching       Use adaptive batching (true/false)
        --max-concurrent-ops      Max concurrent operations (default: 4)
        --memory-threshold-mb     Memory threshold in MB (default: 100)
        --batch-size              Batch size (default: 2)
    
    Examples:
      ./benchmark.swift comprehensive /path/to/document.pdf
      ./benchmark.swift presets /path/to/document.pdf -s
      ./benchmark.swift custom /path/to/document.pdf --parallel false --batch-size 5
    """)
} 