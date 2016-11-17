pro my_ace_plots,dt_beg,dt_end,variables,datapath=datapath,xsize=xsize,ysize=ysize,psym=psym,charsize=charsize,outpath=outpath,outfile=outfile,nonew=nonew,vlines=vlines,vlstyles=vlstyles,vlcolors=vlcolors,vangle=vangle,bvres=bvres,vvres=vvres

;@compile_cdaweb
;Description:	 Compile cdaweb for using this file
;			     before using this to plot ace data you should have already put needed data files into a directory named "plot_root"
;				 and make sure the directory is in your workspace
;Example commad: ace_plots,'2015-11-07','2015-11-08',['V_gsec', 'V_gsmc','Np', 'Tp', 'alpha_ratio'],datapath='/path/to/workspace/which/contains/plot_root'
;
;Date of edit:   2016-10-30
;Commit      :   Pjer

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
  search_path="plot_root"
  file=file_search(search_path+'ac_h0_mfi_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then mfi_files=[mfi_files,file[n_elements(file)-1]]
  file=file_search(search_path+'ac_h0_swe_'+datearr[i]+'_v*.cdf')
  if file[0] ne '' then swe_files=[swe_files,file[n_elements(file)-1]]
  print,file
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

if keyword_set(vlines) then begin
  vlts=(anytim2cdf(vlines)-basetime)/1000.
  if ~keyword_set(vlstyles) then vlstyles=replicate(1,n_elements(vlts))
endif
if ~keyword_set(outpath) then outpath='' else outpath=outpath+'/'
if ~keyword_set(outfile) then outfile=outpath+'ace_'+date_beg+'-'+date_end+'.ps'
if ~keyword_set(pmulti) then pmulti=[0,1,n_var]
if ~keyword_set(xsize) then xsize=16
if ~keyword_set(ysize) then ysize=22
if ~keyword_set(charsize) then charsize=2
if ~keyword_set(psym) then psym=0
if ~keyword_set(avg_int) then avg_int=64. ;sec
bvectors=0
vvectors=0
if ~keyword_set(vangle) then begin
  vangle=fltarr(2,10)
  vangle[0,*]=-90
endif

if ~keyword_set(ystyle_def) then ystyle_def=0
if ~keyword_set(ylog_def) then ylog_def=0
if ~keyword_set(rylog_def) then rylog_def=0
if ~keyword_set(ytickinterval_def) then ytickinterval_def=0
if ~keyword_set(leveline_def) then leveline_def=!values.f_nan
if ~keyword_set(rleveline_def) then rleveline_def=!values.f_nan
k=1.38;*1.e-23
u=2*1.25664;*1.e-6
beta_coef=k*u*1.e-5

xpos=[0.05,0.95]
ypos=reverse((findgen(n_var+1)+0.6)/(n_var+1))

if ~keyword_set(nonew) then begin
  set_plot,'ps'
  device,filename=outfile,xs=xsize,ys=ysize,yoffset=2,xoffset=3,/color
endif
!p.multi=pmulti
!p.charsize=charsize
loadct,39
for i=0,n_var-1 do begin
  variable=variables[i]
  valid_idx_info=0
  time=[0,1]
  values=[0,1]
  ystyle=ystyle_def
  ylog=ylog_def
  rylog=rylog_def
  ytickinterval=ytickinterval_def
  leveline=leveline_def
  rleveline=rleveline_def
  position=[xpos[0],ypos[i+1],xpos[1],ypos[i]]
  case strlowcase(variable) of
    'b_mag': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.magnitude.dat[mfi_tidx]
      valid_idx=where(values ge mfi_data.magnitude.validmin and values le mfi_data.magnitude.validmax)
      valid_idx_info=n_elements(valid_idx)
      if valid_idx[0] ne -1 then yrange=[min(values[valid_idx]),max(values[valid_idx])]
      ytitle=mfi_data.magnitude.lablaxis+' ('+mfi_data.magnitude.units+')'
    end
    'b_gsec': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.bgsec.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[mfi_tidx,*]
      valid_idx_info=lonarr(3)
      for j=0,2 do begin
        valid_idx0=where(values[*,j] ge mfi_data.bgsec.validmin[j] and values[*,j] le mfi_data.bgsec.validmax[j])
	if j eq 0 then begin
	  valid_idx=valid_idx0
	  yrange=[min(values[valid_idx0,j]),max(values[valid_idx0,j])]
	endif else begin
	  valid_idx=[valid_idx,valid_idx0]
	  yrange[0]=yrange[0] < min(values[valid_idx0,j])
	  yrange[1]=yrange[1] > max(values[valid_idx0,j])
	endelse
	valid_idx_info[j]=n_elements(valid_idx)
      endfor
      ytitle='B'+' ('+mfi_data.bgsec.units+', GSE)'
      ylabel=mfi_data.bgsec.labl_ptr_1
      leveline=0
    end
    'b_gsea': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.bgsec.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[mfi_tidx,*]
      valid_idx=where(values[*,0] ge mfi_data.bgsec.validmin[0] and values[*,0] le mfi_data.bgsec.validmax[0] and values[*,1] ge mfi_data.bgsec.validmin[1] and values[*,1] le mfi_data.bgsec.validmax[1] and values[*,2] ge mfi_data.bgsec.validmin[2] and values[*,2] le mfi_data.bgsec.validmax[2])
      b_total=sqrt(values[*,0]^2+values[*,1]^2+values[*,2]^2)
      theta=asin(values[*,2]/b_total)/!dtor
      phi=(atan(values[*,1],values[*,2])/!dtor)/2. ;shrink to -90~90
      values=[[theta],[phi]]
      valid_idx=[valid_idx,valid_idx]
      valid_idx_info=[n_elements(valid_idx)/2.,n_elements(valid_idx)]
      ystyle=9
      yrange=[-90,90]
      ryrange=[0,360]
      ytickinterval=45
      rytickinterval=90
      ytitle='!4h!3 (deg, GSE)'
      rytitle='!4u!3 (deg)'
      ylabel=['Theta','Phi']
      leveline=0
    end
    'b_gsev': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.bgsec.dat
      values=values[*,mfi_tidx]
      for j=0,2 do begin
        valid_idx0=where(values[j,*] ge mfi_data.bgsec.validmin[j] and values[j,*] le mfi_data.bgsec.validmax[j])
        time=time[valid_idx0]
        values=values[*,valid_idx0]
      endfor
      ytitle='B vectors'+' (GSE)'
      ylabel=mfi_data.bgsec.labl_ptr_1
      tres=float(strmid(mfi_data.time_pb5.TIME_RESOLUTION,0,3))
      position0=position
      ;position0[3]-=(position0[3]-position0[1])*2./3.
      if ~keyword_set(bvres) then bvres=4.
      vec1dplot,time,values,position0,xres=tres*bvres,/normalized,title=ytitle,boundaries=vlts,colors=vlcolors,angle=vangle[*,bvectors]
      bvectors+=1
      goto,next2
    end
    'b_gsmc': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.bgsm.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[mfi_tidx,*]
      valid_idx_info=lonarr(3)
      for j=0,2 do begin
        valid_idx0=where(values[*,j] ge mfi_data.bgsm.validmin[j] and values[*,j] le mfi_data.bgsm.validmax[j])
	if j eq 0 then begin
	  valid_idx=valid_idx0
	  yrange=[min(values[valid_idx0,j]),max(values[valid_idx0,j])]
	endif else begin
	  valid_idx=[valid_idx,valid_idx0]
	  yrange[0]=yrange[0] < min(values[valid_idx0,j])
	  yrange[1]=yrange[1] > max(values[valid_idx0,j])
	endelse
	valid_idx_info[j]=n_elements(valid_idx)
      endfor
      ytitle='B'+' ('+mfi_data.bgsm.units+', GSM)'
      ylabel=mfi_data.bgsm.labl_ptr_1
      leveline=0
    end
    'b_gsma': begin
      if ~keyword_set(mfi_data) then goto,next1
      time=mfi_time[mfi_tidx]
      values=mfi_data.bgsm.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[mfi_tidx,*]
      valid_idx=where(values[*,0] ge mfi_data.bgsm.validmin[0] and values[*,0] le mfi_data.bgsm.validmax[0] and values[*,1] ge mfi_data.bgsm.validmin[1] and values[*,1] le mfi_data.bgsm.validmax[1] and values[*,2] ge mfi_data.bgsm.validmin[2] and values[*,2] le mfi_data.bgsm.validmax[2])
      b_total=sqrt(values[*,0]^2+values[*,1]^2+values[*,2]^2)
      theta=asin(values[*,2]/b_total)/!dtor
      phi=(atan(values[*,1],values[*,2])/!dtor)/2. ;shrink to -90~90
      values=[[theta],[phi]]
      valid_idx=[valid_idx,valid_idx]
      valid_idx_info=[n_elements(valid_idx)/2.,n_elements(valid_idx)]
      ystyle=9
      yrange=[-90,90]
      ryrange=[0,360]
      ytickinterval=45
      rytickinterval=90
      ytitle='!4h!3 (deg, GSM)'
      rytitle='!4u!3 (deg)'
      ylabel=['Theta','Phi']
      leveline=0
    end
    'v_gsec': begin
      if ~keyword_set(swe_data) then goto,next1
      time=swe_time[swe_tidx]
      values=swe_data.v_gse.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[swe_tidx,*]
      valid_idx_info=lonarr(3)
      valid_idx=where(values[*,0] ge swe_data.v_gse.validmin[0] and values[*,0] le swe_data.v_gse.validmax[0])
      valid_idx_info[0]=n_elements(valid_idx)
      values[*,0]=-values[*,0]
      yrange=[min(values[valid_idx,0]),max(values[valid_idx,0])]
      for j=1,2 do begin
        valid_idx0=where(values[*,j] ge swe_data.v_gse.validmin[j] and values[*,j] le swe_data.v_gse.validmax[j])
	valid_idx=[valid_idx,valid_idx0]
	if j eq 1 then ryrange=[min(values[valid_idx0,j]),max(values[valid_idx0,j])] $
	else begin
	  ryrange[0]=ryrange[0] < min(values[valid_idx0,j])
	  ryrange[1]=ryrange[1] > max(values[valid_idx0,j])
	endelse
	valid_idx_info[j]=n_elements(valid_idx)
      endfor
      scale=(ryrange[1]-ryrange[0])/(yrange[1]-yrange[0])
      values[*,1:2]=(values[*,1:2]-mean(ryrange))/scale+mean(yrange)
      ytitle='-V!dx!n'+' ('+swe_data.v_gse.units+', GSE)'
      rytitle='V!dy!n & V!dz!n'+' ('+swe_data.v_gse.units+')'
      ylabel=swe_data.v_gse.labl_ptr_1
      ystyle=9
      rleveline=0
    end
    'v_gsmc': begin
      if ~keyword_set(swe_data) then goto,next1
      time=swe_time[swe_tidx]
      values=swe_data.v_gsm.dat
      if (size(values))[1] eq 3 then values=transpose(values)
      values=values[swe_tidx,*]
      valid_idx_info=lonarr(3)
      valid_idx=where(values[*,0] ge swe_data.v_gsm.validmin[0] and values[*,0] le swe_data.v_gsm.validmax[0])
      valid_idx_info[0]=n_elements(valid_idx)
      values[*,0]=-values[*,0]
      yrange=[min(values[valid_idx,0]),max(values[valid_idx,0])]
      for j=1,2 do begin
        valid_idx0=where(values[*,j] ge swe_data.v_gsm.validmin[j] and values[*,j] le swe_data.v_gsm.validmax[j])
	valid_idx=[valid_idx,valid_idx0]
	if j eq 1 then ryrange=[min(values[valid_idx0,j]),max(values[valid_idx0,j])] $
	else begin
	  ryrange[0]=ryrange[0] < min(values[valid_idx0,j])
	  ryrange[1]=ryrange[1] > max(values[valid_idx0,j])
	endelse
	valid_idx_info[j]=n_elements(valid_idx)
      endfor
      scale=(ryrange[1]-ryrange[0])/(yrange[1]-yrange[0])
      values[*,1:2]=(values[*,1:2]-mean(ryrange,/nan))/scale+mean(yrange,/nan)
      ytitle='-V!dx!n'+' ('+swe_data.v_gsm.units+', GSM)'
      rytitle='V!dy!n & V!dz!n'+' ('+swe_data.v_gsm.units+')'
      ylabel=swe_data.v_gsm.labl_ptr_1
      ystyle=9
      rleveline=0
    end
    'np': begin
      if ~keyword_set(swe_data) then goto,next1
      time=swe_time[swe_tidx]
      values=swe_data.np.dat[swe_tidx]
      valid_idx=where(values ge swe_data.np.validmin and values le swe_data.np.validmax)
      valid_idx_info=n_elements(valid_idx)
      if valid_idx[0] ne -1 then yrange=[min(values[valid_idx]),max(values[valid_idx])]
      ytitle='N!dp!n ('+swe_data.np.units+')'
    end
    'tp': begin
      if ~keyword_set(swe_data) then goto,next1
      time=swe_time[swe_tidx]
      values=swe_data.tpr.dat[swe_tidx]
      valid_idx=where(values ge swe_data.tpr.validmin and values le swe_data.tpr.validmax)
      valid_idx_info=n_elements(valid_idx)
      vsw=swe_data.vp.dat[swe_tidx]
      texp=vsw
      index1=where(vsw lt 500, complement=index2)
      if index1[0] ne -1 then texp[index1]=(0.031*vsw[index1]-5.1)^2 ;Richardson & Cane, JGR, 1995
      if index2[0] ne -1 then texp[index2]=(0.51*vsw[index2]-142)
      texp=texp/100.
      tratio=values/texp
      valid_idx0=where(values ge swe_data.tpr.validmin and values le swe_data.tpr.validmax and vsw ge swe_data.vp.validmin and vsw le swe_data.vp.validmax and finite(texp) eq 1 and finite(tratio) eq 1)
      values=values/1.e5
      tratio=tratio/1.e5
      values=[[values],[texp],[tratio]]
      valid_idx=[valid_idx,valid_idx0]
      valid_idx_info=[valid_idx_info,n_elements(valid_idx)]
      valid_idx=[valid_idx,valid_idx0]
      valid_idx_info=[valid_idx_info,n_elements(valid_idx)]
      if valid_idx[0] ne -1 then begin
	yrange=[min([values[valid_idx[0:valid_idx_info[0]-1],0],values[valid_idx0,1]]),max([values[valid_idx[0:valid_idx_info[0]-1],0],values[valid_idx0,1]])]
	ryrange=[min(values[valid_idx0,2]),max(values[valid_idx0,2])]
      endif
      tratio=(tratio-mean(ryrange))/(ryrange[1]-ryrange[0])*(yrange[1]-yrange[0])+mean(yrange)
      values[*,2]=tratio
      ystyle=9
      ytitle='T!dp!n (x10!e5!n K)';+swe_data.tpr.units+')'
      rytitle='T!dp!n/T!dexp!n'
      rleveline=0.5
      ylabel=['T!dp!n','T!dexp!n','T!dp!n/T!dexp!n']
    end
    'alpha_ratio': begin
      if ~keyword_set(swe_data) then goto,next1
      time=swe_time[swe_tidx]
      values=swe_data.alpha_ratio.dat[swe_tidx]
      valid_idx=where(values ge swe_data.alpha_ratio.validmin and values le swe_data.alpha_ratio.validmax)
      valid_idx_info=n_elements(valid_idx)
      values=values
      if valid_idx[0] ne -1 then yrange=[min(values[valid_idx]),max(values[valid_idx])]
      ytitle='N!da!n/N!dp!n ('+swe_data.alpha_ratio.units+')'
    end
    'beta': begin
      if ~keyword_set(mfi_data) or ~keyword_set(swe_data) then goto,next1
      b_time=mfi_time[mfi_tidx]
      v_time=swe_time[swe_tidx]
      bmag=mfi_data.magnitude.dat[mfi_tidx]
      np=swe_data.np.dat[swe_tidx]
      tp=swe_data.tpr.dat[swe_tidx]
      time=-1
      values=-1
      for t=min([b_time,v_time]),max([b_time,v_time]),avg_int do begin
        b_index=where(b_time ge t and b_time lt t+avg_int and bmag ge mfi_data.magnitude.validmin and bmag le mfi_data.magnitude.validmax)
        v_index=where(v_time ge t and v_time lt t+avg_int and np ge swe_data.np.validmin and np le swe_data.np.validmax and tp ge swe_data.tpr.validmin and tp le swe_data.tpr.validmax)
	if b_index[0] eq -1 or v_index[0] eq -1 then continue
	time=[time,(mean(b_time[b_index])+mean(v_time[v_index]))/2.]
	bmag0=mean(bmag[b_index])
	np0=mean(np[v_index])
	tp0=mean(tp[v_index])
	values=[values,np0*tp0/bmag0^2*beta_coef]
      endfor
      if n_elements(time) gt 1 then begin
        time=time[1:n_elements(time)-1]
        values=values[1:n_elements(values)-1]
	valid_idx=lindgen(n_elements(time))
	valid_idx_info=n_elements(valid_idx)
      endif else begin
        valid_idx=[-1]
	valid_idx_info=1
      endelse
      if valid_idx[0] ne -1 then yrange=[min(values[valid_idx]),max(values[valid_idx])]
      ytitle='!4b!3!dp!n'
      ylog=1
      leveline=0.1
    end
    else:
  endcase

next1: 
  if valid_idx_info[0]-0 le 1 then index=[0,1] else index=valid_idx[0:valid_idx_info[0]-1]
  time0=time[index]
  values0=values[index]
  ;if i eq n_var-1 or strlowcase(variables[(i+1) < (n_var-1)]) eq 'b_gsev' then utplot,time0,values0,baseutc,timerange=trange,xstyle=1,ytitle=ytitle,yrange=yrange,ystyle=ystyle,ylog=ylog,ytickinterval=ytickinterval,position=position,psym=psym,xtitle=xtitle $
  if i eq n_var-1 then utplot,time0,values0,baseutc,timerange=trange,xstyle=1,ytitle=ytitle,yrange=yrange,ystyle=ystyle,ylog=ylog,ytickinterval=ytickinterval,position=position,psym=psym,xtitle=xtitle $
  else utplot,time0,values0,baseutc,timerange=trange,xstyle=1,ytitle=ytitle,yrange=yrange,ystyle=ystyle,ylog=ylog,ytickinterval=ytickinterval,/nolabel,xtickname=replicate(' ',60),position=position,psym=psym

  if keyword_set(vlts) then begin
    for j=0,n_elements(vlts)-1 do begin
      if ylog eq 0 then yr=!y.crange else yr=10.^!y.crange
      oplot,[1,1]*vlts[j],yr,linestyle=vlstyles[j]
    endfor
  endif  
  for j=1,n_elements(valid_idx_info)-1 do begin
    if j eq 1 then begin
      xyouts,(timerange[1]-timerange[0])/30,yrange[1]-(yrange[1]-yrange[0])/8.,ylabel[0],charsize=!p.charsize/1.8,charthick=2
      colors=floor(findgen(n_elements(valid_idx_info))/(n_elements(valid_idx_info)-1)*250)
    endif
    if valid_idx_info[j]-valid_idx_info[j-1] le 1 then index=[0,1] else index=valid_idx[valid_idx_info[j-1]:valid_idx_info[j]-1]
    psym0=psym
    if strlowcase(variable) eq 'b_gsea' or strlowcase(variable) eq 'b_gsma' then psym0=3
    oplot,time[index],values[index,j],color=colors[j],psym=psym0
    xyouts,(timerange[1]-timerange[0])/30,yrange[1]-(yrange[1]-yrange[0])/8.*(j+1),ylabel[j],color=colors[j],charsize=!p.charsize/1.8,charthick=2
  endfor
  if finite(leveline) then oplot,[time[0],time[n_elements(time)-1]],[1,1]*leveline,linestyle=2

  if ystyle ge 8 then begin
    axis,yaxis=1,yrange=ryrange,ystyle=(ystyle mod 2),ytickinterval=rytickinterval,ytitle=rytitle,/save,ylog=rylog
    if finite(rleveline) then oplot,[time[0],time[n_elements(time)-1]],[1,1]*rleveline,linestyle=2,color=250
  endif
next2:
endfor
xyouts,mean(xpos),ypos[0]+ysize/20.*0.01,'Data from Advanced Composition Explorer (ACE)',alignment=0.5,/norm,charsize=!p.charsize/1.5

if ~keyword_set(nonew) then device,/close
!p.charsize=1

end
