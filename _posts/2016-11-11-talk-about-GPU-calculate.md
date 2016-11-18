---
layout: article
title:  Talk about GPU calculate
modified: 2016-11-16
image:
  feature: CUDA_Visual.jpg
  teaser: CUDA_Visual.jpg
  thumb: CUDA_Visual.jpg
categories: CUDA[c++]
---

# On the endless way of OPTIMIZING 

CUDA自家出的Nsight竟然可以支持VS2015了（之前只支持到2013）。

所以现在是可以在宇宙最好的IDE里编辑.cu文件，然后丝滑地按下F5直接编译成host和device程序并运行了。

VS2015内新建一个新的CUDA项目的时候，会预先生成一个小sample，sample里是一个GPU内数组相加的小程序，其中Kernel部分是这样的：

```c++
__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}
```

Device码（GPU内运行的部分）调用方式看起来很奇怪：

```c++
addKernel<<<1, size>>>(dev_c, dev_a, dev_b);
```

是用三个尖括号，括号内分别是调用函数使用的GridDim和BlockDim，GPU计算的拓扑结构是grid，grid里有很多block，block又可以分成很多个thread，所以讲GPU是高度并行的，但是最开始搞不懂的就是到底该选多少个block和多少个thread来并行化计算。

因为GPU计算是严重依赖于硬件的，所以针对硬件，Nvidia有一套关于计算能力的评价体系（compute capability table）

![compute cap](/images/blog-article/compute-cap.png)

然后计算能力对应的数据

![grid size](/images/blog-article/grid-size.png)

可以看到grid的x方向的dim大小是 $ 2^{31} -1 = 2147483647  $ 个block 而一个block又可以有1024个thread，所以说这个高度的并行化就体现在这里，而在代码里仅仅是安排每一个thread的行为就行