# 颜色和着色器

对于刚接触图形学的人来说，第一个想要了解的问题，图形学研究的是什么？简要的回答是，图形学研究渲染器中的理论，算法和工程架构。所谓的渲染器不过是一个简单的程序，输入一个描述 3D 场景的场景文件，输出这个场景所对应的一张图片。

大多数人对于图片的概念，不过是电脑上的 JPG 和 PNG 文件。如果使用 Photoshop 之类的软件打开任何一张图片，就会发现图片由一组带颜色的小格子构成，每一个格子称之为像素。对于每一个像素来言，一般来说由三种颜色构成，或者称为三个通道，即红绿蓝通道。每一个通道的取值均为`[0,1]`。对于一些半透明的图片来说，还会引入第四个通道，即透明通道。同样透明通道的的取值范围也是`[0,1]`。

如果一个像素的颜色为`(1,0,0,1)`，像素的四个通道一般情况以`RGBA`的顺序排列，那么很显然这个像素为红色。同样的，如果是`(1,1,0,1)`，那么该像素呈现红色和绿色的混合颜色黄色。

对于每一个像素来说，由于`[0,1]`是一个浮点数，如果我们单纯使用单精度浮点类型`float`进行存储，对于一个包含 RGBA 四通道的像素来说，其大小为 128 个bit，即 16 个 byte。对于一张 1920x1080 分辨率的图片来说，这需要 33177600 个byte，相当于 32MB 的大小。事实上，人眼分辨颜色的能力是有限的，如果我们仅仅使用 8 个 bit 来表示一个通道，那么对于每个通道我们将会获得 256 种颜色。红色，绿色，蓝色的混合可以得到 256x256x256，大约一千六百万种颜色。8 bit 相对 32 bit，每个像素仅仅需要 4 个 byte 即可存储，通过一些合适的压缩算法，我们就能将一张 1920x1080 分辨率的图片合理压缩到 2 \~ 3MB 的大小。

因此，绝大部分的图片和颜色都采用 8 bit 的方式来存储。由于 8 bit 刚好可以用`[0,255]`区间的整数或者是两个 16 进制数表示，很多程序，比如 HTML，就会使用 16 进制颜色编码来，例如`#2980b9ff`，来表示颜色。在 C 语言中，我们则可以使用`char`类型来表示一个通道的数值。

## 第一个实验：C++生成单颜色图片

有了对图片和像素的基本了解，我们不妨在 C++ 做一个小实验来生成一张只有颜色的图片。

既然要生成图片，首先我们要考虑图片的格式。对于绝大多数的图片格式来说，其像素都是由一个一维数组构成。其数组的长度等于图片的宽度乘以图片的高度乘以每个像素的通道数量，即：

$$
len = width * height * channels
$$

​`stb`是一个小巧的 C++ 头文件库，提供了基础图片格式的读写操作。我们可以通过 GitHub 获取，[https://github.com/nothings/stb/blob/master/stb\_image\_write.h](https://github.com/nothings/stb/blob/master/stb\_image\_write.h)。

在此，我们将使用`stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes)`函数将我们的图片数据保存为PNG格式。

`stbi_write_png`函数由六个参数构成，第一个参数是文件路径，第二和第三个参数是图片的宽度和高度。第四个参数表示图片数据的通道数量。由于不需要使用透明通道，因此三通道图片即可满足要求。第五个参数表示图片数据。由于我们的图片数据是一个一维数组，`stride_in_bytes`则表示每行的像素数据的长度。

了解了`stbi_write_png`函数的参数，在我们的例子中，我们可以将其简化为`stbi_write_png(char const *filename, int w, int h, 3, const void *data, w*3)`。

下面关注数据部分。我们只需要生成一张不透明的颜色图，假定其为 200x200 分辨率，同时使用 8 bit 颜色格式。因此，我们只需要声明一段像素数组：

```cpp
char pixels[200 * 200 * 3];
```

最后我们将其组装在一起，得到我们的第一个小程序：

```cpp
// single-color.cpp

// This line is required for stb image library
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_WRITE_STATIC
#include <stb/stb_image_write.h>

int main() {
  int w = 200;
  int h = 200;
  int c = 3;

  char pixels[w * h * c];
  for (auto x = 0; x < w; x++)
    for (auto y = 0; y < h; y++) {
      pixels[(y * w + x) * c + 0] = (char)255;
      pixels[(y * w + x) * c + 1] = (char)0;
      pixels[(y * w + x) * c + 2] = (char)0;
    }

  stbi_write_png("single-color.png", w, h, c, pixels, w * 3);
  return 0;
}
```

我们编译并运行该程序，即可获得一张名为`single_color.png`的红色图片。

![Single Color](assets/01-color/single-color.png)

接下来，我们将在这个基础上，做一些简单的调整，让我们输出的图片更加的漂亮。

## 第二个实验：屏幕空间坐标和着色器

在第一个实验中，我们通过设置像素数组的数值来实现输出颜色的目的。我们不妨把程序做一个稍稍的整理。

首先是颜色，由于每一个像素都由三个通道构成，我们可以如此定义颜色：

```cpp
struct Color {
  char r;
  char g;
  char b;
};
```

那么我们像素数组即变成:

```cpp
Color pixels[width * height];
```

得益于 C++ 的特性，虽然我们增加了`Color`类型，但数据在内存排布上和之前的数组则没有任何差别。

我们再将生成颜色的代码整理成一个函数，以便我们更好的控制颜色的生成过程。

```cpp
Color PixelColor(int x, int y, int width, int height);
```

这里我们注意到，我们需要传递四个参数。然而在渲染过程中，我们大多只关心渲染的结果，而忽略渲染输出的分辨率。同一张图片，只要长宽比相同，1080P 和 4K 应该仅仅只有清晰度的区别，而不会有任何内容上的不同。

对此，我们可以将`PixelColor`函数做一个简单的简化：

```cpp
Color PixelColor(float u, float v);
```

其中`u = x/(float)width`，`v = y/(float)height`。经过此变换，一个像素的颜色仅仅只和这个像素在屏幕上的位置相关，和屏幕的分辨率的大小不相关。

最后，我们将这些组件拼装在一起，并生成一张具有渐变颜色的图片。

```cpp
// gradient-color.cpp

// This line is required for stb image library
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_WRITE_STATIC
#include <stb/stb_image_write.h>

struct Color {
  char r;
  char g;
  char b;
};

Color PixelColor(float u, float v) {
  Color c;
  c.r = (char)(u * 255);
  c.g = (char)(v * 255);
  c.b = 0;
  return c;
}

int main() {
  int w = 200;
  int h = 200;
  int c = 3;

  Color pixels[w * h];
  for (auto x = 0; x < w; x++)
    for (auto y = 0; y < h; y++) {
      auto u = x / (float)w;
      auto v = y / (float)h;
      pixels[y * w + x] = PixelColor(u, v);
    }

  stbi_write_png("gradient-color.png", w, h, c, pixels, w * 3);
  return 0;
}
```

![Gradient Color](assets/01-color/gradient-color.png)

## 像素着色器的魔法

虽然我们的程序很短，实际上我们已经实现了一个完整的像素着色的过程。仅仅依赖于像素着色器，和GPU的并行计算的优势，我们就可以创建无数优美的图画。

[ShaderToy](https://www.shadertoy.com/) 是一家专注于发布和分享像素着色器的平台。无数的艺术家、程序员在上面创建了各种魔法般的图案。

![Shadertoy](assets/01-color/shadertoy.png)

图片来自 [https://www.shadertoy.com/view/ltfXzj](https://www.shadertoy.com/view/ltfXzj)

## 小结

本章节中，我们介绍了图片和颜色的格式，并且通过 C++ 生成了简单的图片。在我们正式进入到渲染管线之前，我们都会通过图片的形式来演示光栅化的过程。

我们还引出了屏幕空间的概念，在本章节的屏幕坐标系中，是一个仅有二维坐标，并且取值范围在`[0,1]`的空间。

紧接着，我们讨论了着色过程和像素着色器。像素着色器真正揭示了 GPU 的并行原理。因为每个像素着色器互不依赖，因此 GPU 才可以同时计算每个像素的颜色。

整个图形学研究的内容就是如何快速地，更逼真地对场景完成整个着色过程。下一章节，我们将从最简单的几何图形出发，为我们的渲染器增加图元渲染的能力。
