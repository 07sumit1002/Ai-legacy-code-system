from flask import Flask, request, send_file, render_template
import pandas as pd
from PIL import Image, ImageDraw, ImageFont
import os
import zipfile
import io

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files['file']
    df = pd.read_excel(file, engine='openpyxl')


    output_zip = io.BytesIO()
    with zipfile.ZipFile(output_zip, 'w') as zf:
        for index, row in df.iterrows():
            name = row['Name']
            cert = generate_certificate(name)
            cert_path = f"certificate_{index}.png"
            cert.save(cert_path)

            zf.write(cert_path)
            os.remove(cert_path)

    output_zip.seek(0)
    return send_file(output_zip, as_attachment=True, download_name="certificates.zip")

def generate_certificate(name):
    template = Image.open("certificate_template.png")
    draw = ImageDraw.Draw(template)
    font = ImageFont.truetype("fonts/arial.ttf", 40)

    text_position = (600, 500)  # adjust based on your template
    draw.text(text_position, name, fill="black", font=font)

    return template

if __name__ == '__main__':
    app.run(debug=True)
