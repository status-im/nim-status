import base64
import chroma
import identicon/color
import md5
import nimage
import nimPNG
import streams

type
  Bitmap* = array[0..24, uint8]
  Identicon* = ref object
    bitmap*: Bitmap
    color*: ColorRGBA
  NimageColor = uint32

proc bitmapFromHash(hash: MD5Digest): Bitmap =
  for i in 0..4:
    for j in 0..4:
      var jCount = j
      if j > 2:
        jCount = 4 - j
      result[5 * i + j] = hash[3 * i + jCount]
  # convert to binary switch
  for k in low(result)..high(result):
    let v = result[k]
    if v mod 2 == 0:
      result[k] = 1
    else:
      result[k] = 0

proc colorFromHash(hash: MD5Digest): ColorRGBA =
  const saturation: float64 = 50
  const lightness: float64  = 70
  # Take the least 3 relevant bytes, and convert to a float between [0..360]
  let sum: float64 = hash[13].float64 + hash[14].float64 + hash[15].float64
  let hue: float64 = (sum / 765) * 360
  color.asRGBA(color.hsl(hue, saturation, lightness))

proc generate(id: string): Identicon =
  let hash = id.toMD5
  let bitmap = bitmapFromHash(hash)
  let color = colorFromHash(hash)
  Identicon(bitmap: bitmap, color: color)

proc renderBase64(icon: Identicon): string =
  let img = newNimage(250, 250)
  # make the background transparent
  const transparent: NimageColor = 0
  img.fill(transparent)
  let bitmap = icon.bitmap
  let color = icon.color
  let r = color.r
  let g = color.g
  let b = color.b
  let a = color.a
  let rgba: NimageColor = nimage.rgba(r, g, b, a)
  const maxRow = 5
  const sizeSquare = 30
  for i in low(bitmap)..high(bitmap):
    if bitmap[i] == 1:
      # compare to: https://github.com/status-im/status-go/blob/develop/protocol/identity/identicon/renderer.go#L41-L46
      # for `image.Rect` of Go the 2nd pair of coords is exclusive upper bound
      # but for `fillRect` used here it is inclusive
      var x0 = (50 + (i mod maxRow) * sizeSquare).uint32
      var y0 = (50 + (i div maxRow) * sizeSquare).uint32
      var x1 = ((50 + (i mod maxRow) * sizeSquare + sizeSquare) - 1).uint32
      var y1 = ((50 + (i div maxRow) * sizeSquare + sizeSquare) - 1).uint32
      img.fillRect(x0, y0, x1, y1, rgba)
      echo x0, "-", y0, "-", x1, "-", y1, "-", rgba, "\n"
  var pixels: seq[uint8]
  for j in low(img.pixels)..high(img.pixels):
    let pix32 = img.pixels[j]
    if pix32 == 0:
      pixels.add(0)
      pixels.add(0)
      pixels.add(0)
      pixels.add(0)
    else:
      pixels.add(r)
      pixels.add(g)
      pixels.add(b)
      pixels.add(a)
  # the following settings encode a PNG that when decoded with nimPNG's
  # `decodePNG32` will consist of the same RGBA uint8 values as when
  # `decodePNG32` is used to decode a PNG produced by status-go's `identicon`
  # for the same input string; the settings were determined by experimentation
  # and testing. See: https://golang.org/src/image/png/writer.go
  let settings = makePNGEncoder()
  settings.autoConvert = false
  settings.filterStrategy = LFS_BRUTE_FORCE
  let png = encodePNG(pixels, LCT_RGBA, 8, 250, 250, settings)
  let strm = newStringStream()
  png.writeChunks(strm)
  strm.flush()
  strm.setPosition(0)
  let encoded = base64.encode(strm.readAll())
  strm.close()
  result = "data:image/png;base64," & encoded

proc generateBase64*(id: string): string =
  let icon = generate(id)
  renderBase64(icon)
