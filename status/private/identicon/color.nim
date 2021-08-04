# vendor libs
from chroma import ColorRGBA

# chroma provides an implementation of HSL using float32:
#  https://github.com/treeform/chroma/blob/master/src/chroma/colortypes.nim#L39-L44
# However, the computations done in Go use float64:
#  https://github.com/lucasb-eyer/go-colorful/blob/master/colors.go#L228-L306
#  https://github.com/lucasb-eyer/go-colorful/blob/master/colors.go#L16-L22
#  https://golang.org/src/image/color/color.go?s=983:1021#L60
# In order to derive identical uint8 values for RGBA an impl of HSL is provided
# here using float64 and the RGBA conversion uses the same formulas

# Color Space: HSL (float64)
type ColorHSL* = object
  h*: float64 ## hue 0 to 360
  s*: float64 ## saturation 0 to 100
  l*: float64 ## lightness 0 to 100

proc hsl*(h: float64, s: float64, l: float64): ColorHSL =
  ColorHSL(h: h, s: s, l: l)

proc asRGBA*(c: ColorHSL): ColorRGBA =
  ## convert ColorHSL to ColorRGBA
  var
    s: float64 = c.s / 100
    l: float64 = c.l / 100
  if s == 0:
    let l_scaled = uint32(l * 65535.0 + 0.5)
    let l_uint8 = uint8(l_scaled div 256)
    result.r = l_uint8
    result.g = l_uint8
    result.b = l_uint8
    result.a = uint8(0xFF)
    return
  var
    h: float64 = c.h / 360
    r, g, b, t1, t2, tr, tg, tb: float64
  if l < 0.5:
    t1 = l * (1.0 + s)
  else:
    t1 = l + s - l * s
  t2 = 2 * l - t1
  tr = h + 1.0 / 3.0
  tg = h
  tb = h - 1.0 / 3.0
  if tr < 0:
    tr += 1.0
  if tr > 1:
    tr -= 1.0
  if tg < 0:
    tg += 1.0
  if tg > 1:
    tg -= 1.0
  if tb < 0:
    tb += 1.0
  if tb > 1:
    tb -= 1.0
  # Red
  if 6 * tr < 1:
    r = t2 + (t1 - t2) * 6 * tr
  elif 2 * tr < 1:
    r = t1
  elif 3 * tr < 2:
    r = t2 + (t1 - t2) * (2.0 / 3.0 - tr) * 6
  else:
    r = t2
  # Green
  if 6 * tg < 1:
    g = t2 + (t1 - t2) * 6 * tg
  elif 2 * tg < 1:
    g = t1
  elif 3 * tg < 2:
    g = t2 + (t1 - t2) * (2.0 / 3.0 - tg) * 6
  else:
    g = t2
  # Blue
  if 6 * tb < 1:
    b = t2 + (t1 - t2) * 6 * tb
  elif 2 * tb < 1:
    b = t1
  elif 3 * tb < 2:
    b = t2 + (t1 - t2) * (2.0 / 3.0 - tb) * 6
  else:
    b = t2
  let r_scaled = uint32(r * 65535.0 + 0.5)
  let g_scaled = uint32(g * 65535.0 + 0.5)
  let b_scaled = uint32(b * 65535.0 + 0.5)
  result.r = uint8(r_scaled div 256)
  result.g = uint8(g_scaled div 256)
  result.b = uint8(b_scaled div 256)
  result.a = uint8(0xFF)
