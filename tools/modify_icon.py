from PIL import Image, ImageDraw, ImageFont
import os

def add_certificate_elements(input_path, output_path):
    try:
        # Open the original image
        img = Image.open(input_path)
        
        # Create a drawing object
        draw = ImageDraw.Draw(img)
        
        # Get image dimensions
        width, height = img.size
        
        # Draw certificate elements
        
        # Certificate outline (bottom right corner)
        cert_width = width * 0.4
        cert_height = height * 0.3
        cert_x = width - cert_width - width * 0.1
        cert_y = height - cert_height - height * 0.1
        
        # Draw certificate background (slightly transparent white)
        draw.rectangle(
            [(cert_x, cert_y), (cert_x + cert_width, cert_y + cert_height)],
            fill=(255, 255, 255, 180)
        )
        
        # Draw certificate border
        draw.rectangle(
            [(cert_x, cert_y), (cert_x + cert_width, cert_y + cert_height)],
            outline=(0, 0, 0), width=3
        )
        
        # Draw certificate lines
        line_spacing = cert_height / 4
        for i in range(1, 4):
            y = cert_y + i * line_spacing
            draw.line(
                [(cert_x + cert_width * 0.1, y), (cert_x + cert_width * 0.9, y)],
                fill=(0, 0, 255), width=2
            )
        
        # Draw certificate seal
        seal_radius = cert_width * 0.15
        seal_x = cert_x + cert_width * 0.8
        seal_y = cert_y + cert_height * 0.8
        draw.ellipse(
            [(seal_x - seal_radius, seal_y - seal_radius), 
             (seal_x + seal_radius, seal_y + seal_radius)],
            fill=(255, 0, 0)
        )
        
        # Draw graduation cap (top left)
        cap_size = width * 0.25
        cap_x = width * 0.2
        cap_y = height * 0.2
        
        # Cap base
        draw.rectangle(
            [(cap_x - cap_size/2, cap_y), (cap_x + cap_size/2, cap_y + cap_size * 0.1)],
            fill=(0, 0, 0)
        )
        
        # Cap top (triangle)
        draw.polygon(
            [(cap_x - cap_size/2, cap_y), 
             (cap_x, cap_y - cap_size * 0.2), 
             (cap_x + cap_size/2, cap_y)],
            fill=(0, 0, 0)
        )
        
        # Tassel
        draw.line(
            [(cap_x, cap_y - cap_size * 0.15), 
             (cap_x + cap_size * 0.3, cap_y + cap_size * 0.15)],
            fill=(255, 215, 0), width=3
        )
        
        # Save the modified image
        img.save(output_path)
        print(f"Modified icon saved to {output_path}")
        return True
    except Exception as e:
        print(f"Error modifying icon: {e}")
        return False

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_path = os.path.join(base_dir, "assets", "icon", "icon.png")
    output_path = os.path.join(base_dir, "assets", "icon", "icon_with_cert.png")
    
    if add_certificate_elements(input_path, output_path):
        # Copy the modified image back to the icon.png
        import shutil
        shutil.copy(output_path, input_path)
        print(f"Original icon replaced with modified version")
        print("Run 'flutter pub run flutter_launcher_icons' to update app icons")
