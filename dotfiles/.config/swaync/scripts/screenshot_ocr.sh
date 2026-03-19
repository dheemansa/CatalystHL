#!/bin/bash

# Define a temporary image file
IMAGE_PATH="/tmp/tmp_ocr.png"

# Use the custom screenshot tool to capture a selection
if ~/.local/bin/screenshot region -f "$IMAGE_PATH" -s; then
    # Run Tesseract OCR and output to stdout
    TEXT=$(tesseract "$IMAGE_PATH" stdout -l eng quiet)
    
    # Check if text was found
    if [ -n "$TEXT" ]; then
        # Copy to clipboard (requires wl-clipboard)
        echo -n "$TEXT" | wl-copy
        
        # Notify the user with the copied text
        notify-send "OCR Successful" "Text copied to clipboard:\n\n$TEXT" -i text-x-generic
    else
        notify-send "OCR Failed" "No text was detected in the selection." -i dialog-error
    fi
    
    # Clean up the temporary image
    rm -f "$IMAGE_PATH"
else
    # The screenshot command failed or was cancelled
    notify-send "OCR Cancelled" "No region selected or capture failed." -i dialog-warning
fi
