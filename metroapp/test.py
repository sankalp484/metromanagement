import qrcode

img = qrcode.make("Hello, world!")
img.save("test_qr.png")
print("QR code generated and saved as test_qr.png")
