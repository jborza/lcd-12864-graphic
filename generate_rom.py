from PIL import Image
# assuming 1bpp 64x128 png
im = Image.open('lenna.png')

def print_row(y):
    #get 8 bits at a time
    for x in range(0,128,8):
        byte = 0
        for x_offset in range(0,8):
            if(x_offset > 0):
                byte = byte << 1
            px = im.getpixel((x+x_offset,y))
            byte = byte | px
        print(f'{byte:08b}')

for y in range(0,32):
    #interlace rows Y and Y+32
    print_row(y)
    print_row(y+32)