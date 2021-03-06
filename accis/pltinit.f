C********************************************************************
c Initialize the plot
      subroutine pltinit(wxi,wxa,wyi,wya)
      real wxi,wxa,wyi,wya
      include 'plotcom.h'
      character*12 str1
c      external initiald

c	write(*,*)' Entering pltinit with nframe,pfsw',nframe,pfsw
      if(nframe.eq.0)then
c      First frame only.
c Update the plot-file state only here to avoid file-writing corruption.
         pfsw=pfnextsw
c  Initialize the screen.
         if(pfsw.ge.0) then
            call svga(scrxpix,scrypix,vmode,ncolor)
         else
            call svganodisplay(scrxpix,scrypix,vmode,ncolor)
         endif
c         write(*,*)'svga ncolor',ncolor,vmode,scrxpix,scrypix
c Normal to screen-y scaling factor: just scrxpix for square pixels,
c GKS scheme uses scrypix=0, n2sy,yoverx already set so omits this.
	 if(scrypix .gt. 1)then
c Attempt to avoid g95 incompatibility.
	    n2sy=float(int(scrxpix))
	    yoverx=float(int(scrypix))/n2sy
	 endif
	 if(pfsw .ne. 0) then
c     Initialize buffer and open file on unit 12.
	    pfilno=pfilno+1
	    write(str1(5:8),'(i4.4)')pfilno
	    str1(1:4)='plot'
	    if(abs(pfsw).eq.1)then
	       str1(9:11)='.hp'
	    else
	       str1(9:11)='.ps'
	    endif
            psini=2
	    call inib(12,str1(1:11))
            if(pfPS.eq.1)call PSfontinit()
	 endif
      endif

      if(nrows.ne.0.and.ncolumns.ne.0)then
	 call mregion
      endif

      call scalewn(wxi,wxa,wyi,wya,.false.,.false.)
      if(nrows.ne.0)then
c	Multiple Frames Code.
	 call vecn(crsrx,crsry,0)
	 nframe=nframe+1
	 if(nframe.eq.nrows*ncolumns)nframe=0
      endif
      call truncf(0.,0.,0.,0.)
      return
      end
C********************************************************************
      blockdata initiald
c Generic parts of initializations.
      include 'plotcom.h'
      data nframe,nrows,ncolumns/0,0,0/
      data naxmin,naxmax,naymin,naymax,naxpt,naypt
     $  / 0.31,0.91,0.1,0.7,0.31,0.1/
      data xticlen,yticlen,xticoff,yticoff,nxlabw,nxlabp,nylabw,nylabp
     $	/ 0.015,0.015,-0.03,-0.02,4,1,4,1 /
      data ticnum/6/
c Now this is initialized by truncf call in pltinit.
c      data  trcxmi,trcxma,trcymi,trcyma,ltlog
c     $	 / 0.,0.,1.,1.,.false. /
      data updown/99/
      data pfsw,pfilno/0,0/
      data pfPS/0/
      end

C********************************************************************
      subroutine pltend()
c Wait for return, then switch to text mode
      include 'plotcom.h'
c	write (*,*)' PLtend, updown=',updown
c This is to ensure that we really complete the previous draw. 
      call vecn(crsrx,crsry,0)
c This gives ps errors:      ltlog=.false.
c Instead this new approach truncates outside window.
      call truncf(0.,0.,0.,0.)
      if(pfsw .ne. 0)then
	 call flushb(12)
      endif
      if(pfsw.ge.0) call txtmode
      updown=99
      if(nrows.ne.0) then
	 call ticset(0.,0.,0.,0.,0,0,0,0)
	 nframe=0
	 ticnum=6
      endif
      return
      end
c*********************************************************************
      subroutine color(li)
c Set line color. li=15 resets. Plotting translates to dashed etc.
      integer li
      include 'plotcom.h'
      integer wid
      character*6 spchr
      ncolor=li
c      write(*,*)' color: updown=',updown
      if(pfsw.ne.0) then
	 updown=99
	 if(abs(pfsw).eq.2.or.abs(pfsw).eq.3) call abufwrt(' ST',3,12)
	 if(li.lt.15 )then
	    spchr(1:3)=' SP'
c	    call abufwrt(' SP',3,12)
	    if(abs(pfsw).eq.2 .or. abs(pfsw).eq.3) then
	       call iwrite(mod(li,16),wid,spchr(4:6))
	    else
	       call iwrite(mod(li,8)+1,wid,spchr(4:6))
c	       call ibufwrt(mod(li,8)+1,12)
	    endif
	    call abufwrt(spchr(1:3+wid)//' ',4+wid,12)
	 else
	    call abufwrt(' SP15 ',6,12)
	 endif
      endif
      if(pfsw.ge.0) call scolor(li)
      return
      end
C********************************************************************
      subroutine multiframe(irows,icolumns,itype)
c Set multiple frame parameters.
      integer irows,icolumns,itype
      include 'plotcom.h'
      nframe=0
      nrows=irows
      ncolumns=icolumns
      multype=itype
      if(nrows.eq.0) then
	nrows=1
	ncolumns=1
	call mregion
 	call axregion(0.31,0.91,0.1,0.7)
	nrows=0
      endif
      end
c*********************************************************************
      subroutine mregion
c	Multiple Frames Code.
      real csl,xsp,ysp,ytop
      include 'plotcom.h'
      csl=1./sqrt(sqrt(float(nrows*ncolumns)))
C	Gaps for x and y are denoted by bit 0 and 1 of multype.
      ysp=multype/2
      xsp=multype-ysp*2
      ytop=yoverx*0.95
c Adjust the labeling
      call charsize(0.015*csl,0.015*csl)
c Try crunching up the y-labels for better clearance
c was     call ticset(.015*csl,0.15*csl,-.03*csl,-.02*csl,0,0,0,0)
c also made the xsp 0.22 instead of 0.2
      call ticset(.015*csl,0.15*csl,-.03*csl,-.017*csl,0,0,0,0)
      ticnum=7-min(3,2*max(nrows-1,ncolumns-1))
      call axregion(0.1+(nframe/nrows)*(0.88/ncolumns),
     $	  0.1+(nframe/nrows +(1.-0.22*xsp))*(0.88/ncolumns),
     $	  ytop*(0.1+0.9*(nrows-nframe+(nframe/nrows)*nrows-1)/nrows),
     $	  ytop*(0.1+0.9*(nrows-nframe+(nframe/nrows)*nrows-0.2*ysp)
     $	  /nrows)     )
      end
c****************************************************************************
      subroutine setframe(i)
      integer i
      include 'plotcom.h'
      nframe=i
      call mregion
      end
c******************************************************************
      subroutine fitinit(xmin,xmax,ymin,ymax)
      real xmin,xmax,ymin,ymax
      include 'plotcom.h'
      real xfac,xdelta,fxmin,fymin,fxmax,fymax
      integer nxfac
      call fitrange(xmin,xmax,ticnum,nxfac,xfac,xdelta,fxmin,fxmax)
      call fitrange(ymin,ymax,ticnum,nxfac,xfac,xdelta,fymin,fymax)
      call pltinit(fxmin,fxmax,fymin,fymax)
      end
c******************************************************************
c Initialize and set region to retain aspect ratio.
      subroutine pltinaspect(wxi,wxa,wyi,wya)
      real wxi,wxa,wyi,wya
      include 'plotcom.h'
      real xna,xni,yna,yni

      call pltinit(wxi,wxa,wyi,wya)
c After the pltinit call the common yoverx
c     defines the aspect ratio of the entire drawing surface.
c However if we have multi-frames we need to use the current axregion
      xna=naxmax
      yni=naymin
      if((wxa-wxi).eq.0)then
         write(*,*)'PLTINASPECT Error: equal x-coordinates'
         return
      endif
      ywoxw=(wya-wyi)/(wxa-wxi)
      yroxr=(naymax-naymin)/(naxmax-naxmin)
      if(ywoxw .ge. yroxr)then
c frame narrower than region. Center horizontally
         xna=xna-0.5*((naxmax-naxmin)-(naymax-naymin)/ywoxw)
         yna=yroxr*(naxmax-naxmin)+yni
         xni=xna-(yna-yni)/ywoxw
      else
c frame wider than region.
         xni=naxmin
c Shift to center it.
         yni=yni+0.5*((naymax-naymin)-(xna-xni)*ywoxw)
         yna=yni+(xna-xni)*ywoxw
      endif
      call axregion(xni,xna,yni,yna)
      call scalewn(wxi,wxa,wyi,wya,.false.,.false.)
      end
c********************************************************************
      function igetcolor()
      include 'plotcom.h'
      integer getcolor
      igetcolor=ncolor
      end
c**************************************************************************
c Return the argc and argv of the call as integer and single string.
c This can then be used subsequently in C routines.
c For the intel fortran compiler. Add dummy progname at start.
      subroutine cmdlineargs(argc,argv)
      integer argc
      character*(*) argv
      character*(512) arg,cmtemp
      cmtemp='progname'
      argc=iargc()+1
      do i=1,argc-1
         call getarg(i,arg)
         argv=cmtemp(1:istrnonspace(cmtemp)+1)//arg
         cmtemp=argv
      enddo
c Terminate for return to C.
      call termchar(argv)
c      write(*,*)"ifcargs got:",argv," argc=",argc
      end

c**************************************************************************
c Return the length of the string to the last non-space character.
      function istrnonspace(string)
      character*(*) string
      do 1 i=len(string),1,-1
         if(ichar(string(i:i)) .ne. ichar(' ')) goto 2
 1    continue
 2    istrnonspace=i
      end

