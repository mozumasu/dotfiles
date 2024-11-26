from matplotlib import colormaps


# cmap_plasma = colormaps.get_cmap("gist_ncar")
#
# split_num = 11
# offset = split_num - 10


# cmap_plasma = colormaps.get_cmap("gnuplot2")
#
# split_num = 18
# offset = split_num - 10

cmap_plasma = colormaps.get_cmap("rainbow")

split_num = 12
offset = split_num - 10

reverse = True


# get hex color list
color_list = [cmap_plasma(i) for i in range(0, 256, 256 // (split_num - 1))]
if reverse:
    color_list = color_list[::-1]
hex_color_list = [
    f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}" for r, g, b, _ in color_list
]
for i, color in enumerate(hex_color_list):
    if reverse:
        i = i + 1
    else:
        i = i + 1 - offset
    if i > 0:
        string = f"cmap_{i} = 0xff{color[1:]},"
        print(string)
