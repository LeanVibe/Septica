#!/usr/bin/env python3
"""
Romanian Septica App Store Screenshot Overlay Generator

This script adds Romanian cultural text overlays and feature callouts to captured screenshots.
Designed to highlight the authentic Romanian heritage and premium gaming experience.
"""

import os
import json
from PIL import Image, ImageDraw, ImageFont
import sys
from pathlib import Path

# Romanian flag colors
ROMANIAN_BLUE = "#004C9F"
ROMANIAN_YELLOW = "#FCD535"
ROMANIAN_RED = "#CE1126"
ROMANIAN_COLORS = [ROMANIAN_BLUE, ROMANIAN_YELLOW, ROMANIAN_RED]

# App Store standard colors
APP_STORE_BLACK = "#000000"
APP_STORE_WHITE = "#FFFFFF"
APP_STORE_GRAY = "#8E8E93"

class ScreenshotOverlayGenerator:
    def __init__(self, base_dir):
        self.base_dir = Path(base_dir)
        self.metadata_file = self.base_dir / "screenshot_metadata.json"
        self.metadata = self.load_metadata()
        
    def load_metadata(self):
        """Load screenshot metadata from JSON file"""
        try:
            with open(self.metadata_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"❌ Metadata file not found: {self.metadata_file}")
            return {}
    
    def get_font_path(self, weight='regular'):
        """Get system font path for different weights"""
        # Try to find system fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/Arial.ttf", 
            "/Library/Fonts/Arial.ttf",
            "/System/Library/Fonts/Geneva.ttf"
        ]
        
        for path in font_paths:
            if os.path.exists(path):
                return path
        
        # Fallback to default
        return None
    
    def create_overlay_text(self, image, text, position, font_size, color, weight='regular', stroke_width=0, stroke_fill=None):
        """Add text overlay to image"""
        draw = ImageDraw.Draw(image)
        
        try:
            font_path = self.get_font_path(weight)
            if font_path:
                font = ImageFont.truetype(font_path, font_size)
            else:
                font = ImageFont.load_default()
        except:
            font = ImageFont.load_default()
        
        # Add text with optional stroke
        if stroke_width > 0 and stroke_fill:
            draw.text(position, text, font=font, fill=color, stroke_width=stroke_width, stroke_fill=stroke_fill)
        else:
            draw.text(position, text, font=font, fill=color)
        
        return image
    
    def add_gradient_overlay(self, image, start_color, end_color, position, size, opacity=0.8):
        """Add gradient overlay for better text readability"""
        overlay = Image.new('RGBA', image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        
        # Simple gradient simulation with rectangles of varying opacity
        x, y = position
        width, height = size
        
        for i in range(height):
            alpha = int(opacity * 255 * (1 - i / height))
            color = (*start_color, alpha) if isinstance(start_color, tuple) else (*tuple(int(start_color[1:][i:i+2], 16) for i in (0, 2, 4)), alpha)
            draw.rectangle([x, y + i, x + width, y + i + 1], fill=color)
        
        # Composite overlay onto image
        return Image.alpha_composite(image.convert('RGBA'), overlay).convert('RGB')
    
    def process_main_menu_screenshot(self, input_path, output_path, device_type):
        """Process main menu screenshot with Romanian cultural overlay"""
        print(f"🏠 Processing main menu screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            
            # Convert to RGBA for overlay work
            image = image.convert('RGBA')
            
            # Add gradient overlay at top for better text readability
            gradient_height = int(height * 0.3)
            image = self.add_gradient_overlay(
                image, 
                (0, 0, 0), 
                (0, 0, 0), 
                (0, 0), 
                (width, gradient_height), 
                opacity=0.4
            )
            
            # Main title overlay
            title_font_size = int(width * 0.08) if device_type.startswith('iPhone') else int(width * 0.06)
            subtitle_font_size = int(width * 0.045) if device_type.startswith('iPhone') else int(width * 0.035)
            
            # Romanian title
            title_y = int(height * 0.1)
            self.create_overlay_text(
                image,
                "Experience Authentic Romanian Card Gaming",
                (int(width * 0.05), title_y),
                title_font_size,
                APP_STORE_WHITE,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_BLACK
            )
            
            # Romanian subtitle
            subtitle_y = title_y + title_font_size + 10
            self.create_overlay_text(
                image,
                "Jocul Tradițional Românesc",
                (int(width * 0.05), subtitle_y),
                subtitle_font_size,
                ROMANIAN_YELLOW,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            # Feature highlight at bottom
            feature_y = int(height * 0.85)
            feature_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            
            self.create_overlay_text(
                image,
                "• Authentic Romanian Rules • Premium AI Opponent • Cultural Heritage Design",
                (int(width * 0.05), feature_y),
                feature_font_size,
                APP_STORE_WHITE,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            # Save processed image
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_gameplay_screenshot(self, input_path, output_path, device_type):
        """Process gameplay screenshot with rule highlights"""
        print(f"🎮 Processing gameplay screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            image = image.convert('RGBA')
            
            # Title overlay
            title_font_size = int(width * 0.06) if device_type.startswith('iPhone') else int(width * 0.045)
            
            self.create_overlay_text(
                image,
                "7s Beat Any Card - Traditional Romanian Rules",
                (int(width * 0.05), int(height * 0.08)),
                title_font_size,
                ROMANIAN_RED,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_WHITE
            )
            
            # Rule explanation
            rule_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            self.create_overlay_text(
                image,
                "Șaptele bate orice carte • Authentic Romanian Strategy",
                (int(width * 0.05), int(height * 0.88)),
                rule_font_size,
                APP_STORE_WHITE,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_accessibility_screenshot(self, input_path, output_path, device_type):
        """Process accessibility screenshot"""
        print(f"♿ Processing accessibility screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            image = image.convert('RGBA')
            
            title_font_size = int(width * 0.06) if device_type.startswith('iPhone') else int(width * 0.045)
            
            self.create_overlay_text(
                image,
                "Inclusive Gaming for All Romanian Heritage Enthusiasts",
                (int(width * 0.05), int(height * 0.08)),
                title_font_size,
                ROMANIAN_BLUE,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_WHITE
            )
            
            feature_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            self.create_overlay_text(
                image,
                "VoiceOver • Dynamic Type • High Contrast • Cultural Respect",
                (int(width * 0.05), int(height * 0.88)),
                feature_font_size,
                APP_STORE_WHITE,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_cultural_heritage_screenshot(self, input_path, output_path, device_type):
        """Process cultural heritage screenshot"""
        print(f"🏛️ Processing cultural heritage screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            image = image.convert('RGBA')
            
            title_font_size = int(width * 0.06) if device_type.startswith('iPhone') else int(width * 0.045)
            
            self.create_overlay_text(
                image,
                "Preserving Romanian Card Game Traditions",
                (int(width * 0.05), int(height * 0.08)),
                title_font_size,
                ROMANIAN_YELLOW,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_BLACK
            )
            
            heritage_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            self.create_overlay_text(
                image,
                "Păstrăm tradițiile jocurilor românești cu mândrie",
                (int(width * 0.05), int(height * 0.88)),
                heritage_font_size,
                APP_STORE_WHITE,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_statistics_screenshot(self, input_path, output_path, device_type):
        """Process statistics screenshot"""
        print(f"📊 Processing statistics screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            image = image.convert('RGBA')
            
            title_font_size = int(width * 0.06) if device_type.startswith('iPhone') else int(width * 0.045)
            
            self.create_overlay_text(
                image,
                "Track Your Romanian Card Game Journey",
                (int(width * 0.05), int(height * 0.08)),
                title_font_size,
                ROMANIAN_BLUE,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_WHITE
            )
            
            stats_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            self.create_overlay_text(
                image,
                "Progress • Achievements • Cultural Milestones",
                (int(width * 0.05), int(height * 0.88)),
                stats_font_size,
                APP_STORE_WHITE,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_victory_screenshot(self, input_path, output_path, device_type):
        """Process victory screenshot"""
        print(f"🏆 Processing victory screenshot: {device_type}")
        
        try:
            image = Image.open(input_path)
            width, height = image.size
            image = image.convert('RGBA')
            
            title_font_size = int(width * 0.06) if device_type.startswith('iPhone') else int(width * 0.045)
            
            self.create_overlay_text(
                image,
                "Celebrate Your Romanian Heritage Victories",
                (int(width * 0.05), int(height * 0.08)),
                title_font_size,
                ROMANIAN_RED,
                weight='bold',
                stroke_width=2,
                stroke_fill=APP_STORE_WHITE
            )
            
            victory_font_size = int(width * 0.035) if device_type.startswith('iPhone') else int(width * 0.025)
            self.create_overlay_text(
                image,
                "Felicitări! Ai câștigat cu stilul românesc!",
                (int(width * 0.05), int(height * 0.88)),
                victory_font_size,
                ROMANIAN_YELLOW,
                stroke_width=1,
                stroke_fill=APP_STORE_BLACK
            )
            
            image.convert('RGB').save(output_path, 'PNG', quality=95)
            print(f"✅ Saved: {output_path}")
            
        except Exception as e:
            print(f"❌ Error processing {input_path}: {e}")
    
    def process_screenshots_for_device(self, device_type):
        """Process all screenshots for a specific device type"""
        device_dir = self.base_dir / device_type
        raw_dir = device_dir / "Raw"
        processed_dir = device_dir / "Processed"
        
        if not raw_dir.exists():
            print(f"⚠️  Raw directory not found: {raw_dir}")
            return
        
        # Create processed directory
        processed_dir.mkdir(exist_ok=True)
        
        # Screenshot processing mapping
        screenshot_processors = {
            "01_main_menu.png": self.process_main_menu_screenshot,
            "02_gameplay.png": self.process_gameplay_screenshot,
            "03_accessibility.png": self.process_accessibility_screenshot,
            "04_cultural_heritage.png": self.process_cultural_heritage_screenshot,
            "05_statistics.png": self.process_statistics_screenshot,
            "06_victory.png": self.process_victory_screenshot
        }
        
        for filename, processor in screenshot_processors.items():
            raw_path = raw_dir / filename
            processed_path = processed_dir / filename
            
            if raw_path.exists():
                processor(raw_path, processed_path, device_type)
            else:
                print(f"⚠️  Screenshot not found: {raw_path}")
    
    def process_all_screenshots(self):
        """Process screenshots for all device types"""
        device_types = ["iPhone_6.7", "iPhone_6.5", "iPhone_5.5", "iPad_12.9", "iPad_11.0"]
        
        print("🇷🇴 Starting Romanian Septica Screenshot Overlay Generation")
        print("=========================================================")
        
        for device_type in device_types:
            print(f"\n📱 Processing {device_type}...")
            self.process_screenshots_for_device(device_type)
        
        print("\n🎉 Screenshot overlay generation complete!")
        print(f"📁 Processed screenshots saved in */Processed/ directories")

def main():
    if len(sys.argv) > 1:
        base_dir = sys.argv[1]
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    
    generator = ScreenshotOverlayGenerator(base_dir)
    generator.process_all_screenshots()

if __name__ == "__main__":
    main()