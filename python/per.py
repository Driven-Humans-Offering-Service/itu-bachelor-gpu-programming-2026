import struct
from io import BytesIO

from utils import rootFolder

# row wise
list = [5, 6, 9, 5, 7, 8, 4, 5, 3, 2, 3, 6, 1, 1, 2, 3]
size = 4


buffer = BytesIO()
buffer.write(struct.pack("<i", size))
for el in list:
    buffer.write(struct.pack("<f", el))


with open(f"{rootFolder}/data/input/matrix_{0}_{size}", "wb") as f:
    f.write(buffer.getvalue())
