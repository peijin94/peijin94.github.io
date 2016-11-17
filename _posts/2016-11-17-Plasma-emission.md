---
layout: article
title:  Plasma emission
modified: 2016-11-7
image:
  feature: solar-plasma-teaser.jpg
  teaser: solar-plasma.jpg
  thumb: solar-plasma.jpg
categories: plasma
---

# 关于等离子体辐射（1）

### 经典电动力学角度

从电动力学的角度出发，在无电荷和中性等离子体的假设下可以得到以下关系

$$ \nabla\times E = -\;\frac{\partial{B}}{\partial{t}}\ $$

$$    \nabla\times H = \frac{\partial{D}}{\partial{t}}\ $$

$$    \nabla\cdot D = 0  $$

$$   \nabla\cdot B = 0  $$

公式中场是时间和空间的函数，所以可以进行傅里叶变换：

$$F(k,\omega) = \iiint dr \int dt F(r,t)e^{i(\omega t - k\cdot r)} $$

变换之后有如下关系：

$$ ik\times E = -\;\frac{i\omega}{c} B\ $$  

$$    ik\times H = \frac{i\omega}{c} D\ $$  

$$    ik\cdot D = 0  $$  

$$   ik\cdot B = 0  $$  

消去BD可得:


$$\left[k^2 I - kk - \frac{\omega^2}{c^2}\epsilon(k,\omega)\right]\cdot E(l,\omega) = 0 $$

即为色散方程

确定了电导率系数的情况下可以导出无背景磁场情况下的色散关系从而进一步分析截止频率之类的性质。

### 动理论角度



< 未完待续 >