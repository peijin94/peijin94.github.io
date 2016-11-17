---
layout: article
title:  Solar Data Fetch and Process
modified: 2016-11-17
image:
  feature: blog-article/solar.jpg
  teaser: solar.jpg
  thumb: solar.jpg
categories: [Data, idl, SDO]
---

# Art of Data（AIA数据的获得和处理）

太阳观测主要是以图像数据和谱数据为主，SDO是2013年发射的，搭载了4096*4096的高空间分辨率以及12s每帧的近乎连续的高时间分辨率的AIA。可以得到紫外和极紫外多个波段高精度图片数据。  

JSOC地址：[http://jsoc.stanford.edu/ajax/lookdata.html](http://jsoc.stanford.edu/ajax/lookdata.html)

然后是选数据：  

![image](/images/blog-article/select-data-aia.png)

关键字挺多的，官方也提供了一个完整的文档具体讲关键字的含义，不过仅仅是逻辑很简单的数据的获取只会用到很少的关键字  ,比如图中这个aia.lev1_euv_12s\[2013.1.1_00:00/2h@1m\]\[WAVELNTH=304\] 这个数据获取字段表示的是取从2013年1月1日开始的两个小时的数据，时间精度是每分钟一次，波长是171。

点击Fetch keyword values for record set 可以看到刚才所说的数据获取字段所对应的具体的数据文件名列：

![image](/images/blog-article/select-data-aia-1.png)

然后在这个地方检察一下数据名是否正确（上一步正确的话这一步一般不会有问题），然后就是EXPORT导出数据：

![image](/images/blog-article/select-data-aia-2.png)

只有一个地方需要修改：文件类型-ftp_tar，这种是吧需要的数据打包成一个大包然后给一个固定下载链接，否则如果是url的话会给每个fits文件的路径然后只能逐个点击那样很麻烦，所以一定要用ftp tar   

通常情况下文件不要太大，超过2G一般下载到一半会suspend，所以如果需要的数据量很大的时候尽量分成几个或者试试idl里获取数据（vso_search和vso_get）。注意一定一定不要用迅雷等p2p的支持多线程下载的工具进行下载。JSOC服务器比较脆弱，已经因为多线程下载跪了好几次了，也发过来过警告，所以为了大家都能用数据，还是wget或者curl吧 : )  

  

像这样直接下载的数据是level-1的数据，没有经过标定，太阳的圆心不一定在图片的正中间，以及曝光度之类的，所以要进行定标。使用的是ssw里的aia_prep：

![image](/images/blog-article/select-data-aia-3.png)

官方给出的使用例程：  

The following calling sequence reads an AIA file, re-spikes it, and then preps it:  

IDL> read_sdo, aia_file, index, data  
IDL> aia_respike, index, data, out_index, out_data  
IDL> aia_prep, out_index, out_data, final_index, final_data, /use_pnt_file  

The keyword /use_pnt_file forces aia_prep to get pointing information from the AIA pointing database, rather than trust the values in the FITS header.  



<保留版权，转载标明出处>