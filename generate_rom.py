from PIL import Image
# assuming 1bpp 64x128 png
im = Image.open('lenna.png')

x=0
y=0


for y in range(0,32):
    #first row
    #get 8 bits at a time
    for x in range(0,128,8):
        byte = 0
        for x_offset in range(0,8):
            if(x_offset > 0):
                byte = byte << 1
            px = im.getpixel((x+x_offset,y))
            byte = byte | px
        print(f'{byte:08b}')
    #second row
    for x in range(0,128,8):
        byte = 0
        for x_offset in range(0,8):
            if(x_offset > 0):
                byte = byte << 1
            px = im.getpixel((x+x_offset,y+32))
            byte = byte | px
        print(f'{byte:08b}')