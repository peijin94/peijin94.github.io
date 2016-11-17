---
layout: article
title:  ACE data process
modified: 2016-11-16
image:
  feature: solar-wind.jpg
  teaser: solar-wind-thumb.jpg
  thumb: solar-wind.jpg
categories: idl
---

# 修改idlpackage的一个.pro程序使它更通用

最近有用到太阳风数据的需求，去服务器找数据和程序，找到一个ace_plots.pro看起来是画ace图的程序，但是按照我需要的日期和边量输入之后没有得到我需要的图而是空白图。  

下面是一部分程序（包含变量定义和路径组织）  

【没注释看起来好心塞  : ( 】

``` idl
pro ace_plots,dt_beg,dt_end,variables,datapath=datapath,xsize=xsize,ysize=ysize,psym=psym,charsize=charsize,outpath=outpath,outfile=outfile,nonew=nonew,vlines=vlines,vlstyles=vlstyles,vlcolors=vlcolors,vangle=vangle,bvres=bvres,vvres=vvres

;@compile_cdaweb
if ~keyword_set(datapath) then datapath='' else datapath=datapath+'/'
n_var=n_elements(variables)
if n_var eq 0 then begin
  print,'At least one variable must be specified. It could be B_mag, B_gsec, B_gsev, B_gsea, B_gsmc, B_gsma, V_gsec, V_gsmc, Np, Tp, alpha_ratio, Beta'
  return
endif

utc_beg=anytim2utc(dt_beg)
cdft_beg=anytim2cdf(dt_beg)
utc_end=anytim2utc(dt_end)
cdft_end=anytim2cdf(dt_end)
trange=[utc_beg,utc_end]
timerange=[cdft_beg,cdft_end]
timespan=(cdft_end-cdft_beg)/1000.
if timespan le 0 then begin
  print,'Begin time must be earlier than end time!'
  return
endif
dayspan=floor(timespan/86400.)+1
date_beg=strmid(utc2str(utc_beg,/ECS,/truncate),0,10)
date_end=strmid(utc2str(utc_end,/ECS,/truncate),0,10)
date_beg=strmid(date_beg,0,4)+strmid(date_beg,5,2)+strmid(date_beg,8,2)
date_end=strmid(date_end,0,4)+strmid(date_end,5,2)+strmid(date_end,8,2)
datearr=ymds2datearray(strmid(date_beg,0,4),strmid(date_beg,4,2),strmid(date_beg,6,2),dayspan+1)
res=strmatch(datearr,date_end)
pos=where(res eq 1)
if pos[0] eq -1 then begin
  print,'Can not recognize begin/end date!'
  return
endif
datearr=datearr[0:pos]
n_date=n_elements(datearr)

mfi_files=''
swe_files=''
for i=0,n_date-1 do begin
  year=strmid(datearr[i],0,4)
  mon=strmid(datearr[i],4,2)
  search_path=datapath+year+'_'+mon
  file=file_search(search_path+'/ac_h0_mfi_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then mfi_files=[mfi_files,file[n_elements(file)-1]]
  file=file_search(search_path+'/ac_h0_swe_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then swe_files=[swe_files,file[n_elements(file)-1]]
endfor
print,' '
print,'Load data from -------------------------------'
print,mfi_files
print,swe_files
print,'----------------------------------------------'

if n_elements(mfi_files) gt 1 then begin
  mfi_data=read_mycdf('',mfi_files[1:n_elements(mfi_files)-1],all=1) 
  mfi_time=mfi_data.epoch.dat
endif else mfi_time=!values.f_nan
if n_elements(swe_files) gt 1 then begin
  swe_data=read_mycdf('',swe_files[1:n_elements(swe_files)-1],all=1) 
  swe_time=swe_data.epoch.dat
endif else swe_time=!values.f_nan
;basetime=min([mfi_time[0],swe_time[0]],/nan)
basetime=cdft_beg
mfi_time=(mfi_time-basetime)/1000.
swe_time=(swe_time-basetime)/1000.
timerange=(timerange-basetime)/1000.
mfi_tidx=where(mfi_time ge timerange[0] and mfi_time le timerange[1])
swe_tidx=where(swe_time ge timerange[0] and swe_time le timerange[1])
baseutc=utc_beg
xtitle='Time (start from '+utc2str(baseutc,/VMS,/truncate)+')'

......
```

经过分析，问题出在路径上，大概是这个程序本身是用于图片的  

为了更明白的了解数据的组织形式，在数据库中生成了ACE数据的文件树，服务器中的文件树如下所示：

/database/ACE

*   beacon
*   epd
    * 1997

      ......
    * 2013
*   epm_h1
    * 1997

      ......
    * 2015
*   mag
    * 1997
    * 1998
    * 1999
    * 1hr_average
    * 2000

      ......
    * 2013
    * HDF_data
    * temp
*   mfi_h0
    * 2015
*   mfi_k0
    * 2011

      ......
    * 2015
*   sis_h1
    * 1997

      ......
    * 2015
*   sis_h2
    * 1997

      ......
    * 2014
*   swe_h0
    * 2015
*   swe_k0
    * 2010

      ......
    * 2014
*   swepam
    *  64_sec
       * 1998

         ......
       * 2013
    *  one_hour
*   SWICS
*   swi_h2
    * 1998

      ......
    * 2011
*   ule_h1
    * 2014
*   ule_h2
    * 1998

      ......
    * 2014

170 directories  

可以看到在代码中有

```idl
for i=0,n_date-1 do begin
  year=strmid(datearr[i],0,4)
  mon=strmid(datearr[i],4,2)
  search_path=datapath+year+'_'+mon
  file=file_search(search_path+'/ac_h0_mfi_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then mfi_files=[mfi_files,file[n_elements(file)-1]]
  file=file_search(search_path+'/ac_h0_swe_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then swe_files=[swe_files,file[n_elements(file)-1]]
endfor
```

所以程序所对应的文件路径应该是如下格式

/database/ACE

* 2015_07

  * ac_h0\_mfi\_ 20150718.cdf

    ......


所以为了能使用这个程序需要修改一下数据文件索引的部分，就是这个循环内会指派一个YYYY_MM格式的时间文件夹作为search_path，而且下面会根据时间来寻找对应的mfi和swe文件，而普通用户对数据库只有读权限，所以最方便的方法是把数据拷贝到本地的一个文件夹假设是plot_root，然后以这个问件夹为寻找数据的根目录，总之每次程序会根据时间段去寻找需要的数据的问件名，所以就把所有可能用到的问件统一放在一个固定的文件夹内然后把程序的寻找问件的部分修改成

```idl
for i=0,n_date-1 do begin
  search_path='./plot_root'
  file=file_search(search_path+'/ac_h0_mfi_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then mfi_files=[mfi_files,file[n_elements(file)-1]]
  file=file_search(search_path+'/ac_h0_swe_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then swe_files=[swe_files,file[n_elements(file)-1]]
endfor
```

然后以以下形式调用：

``` idl
ace_plots,'2015-11-07','2015-11-08',['V_gsec', 'V_gsmc','Np', 'Tp', 'alpha_ratio'],datapath='/path/to/workspace/which/contains/plot_root'
```

就可以给出正确的图片，当然，在运行这个画图序之前要编译一下cdaweb，运行命令@compile_cdaweb，就成

结果：

![image](/images/blog-article/ace-plot.png)

修改之后加了点注释的文件: [new_ace_plots.pro](/assets/new_ace_plots.pro)