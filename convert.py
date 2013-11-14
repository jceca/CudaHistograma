import sys, Image
 
original = Image.open(sys.argv[1])
gray = original.convert("L")

image_size = original.size

header_file = open('image.h', 'w', -1)
header_file.write('#define IMAGE_WIDTH {0}\n'.format(image_size[0]))
header_file.write('#define IMAGE_HEIGHT {0}\n\n'.format(image_size[1]))
header_file.write('static unsigned char image[IMAGE_WIDTH * IMAGE_HEIGHT] = {\n')

for i, px in enumerate(gray.getdata()):
    if i > 0:
        header_file.write(', {0}'.format(px))
    else:
        header_file.write('{0}'.format(px))
header_file.write('\n};\n')

print gray.histogram()

