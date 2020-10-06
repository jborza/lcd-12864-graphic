from PIL import Image
# assuming 1bpp 64x128 png
im = Image.open('che2.png')
# read pixels by bytes
x=0
y=0
for y in range(0,64):
    #get 8 bits
    for x in range(0,128,8):
        byte = 0
        for x_offset in range(0,8):
            if(x_offset > 0):
                byte = byte << 1
            px = im.getpixel((x+x_offset,y))
            byte = byte | px
        #   print(byte)
        print(f'{byte:08b}')