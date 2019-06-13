#!/bin/sh
echo "build: welcome to obsproc_global sorc build script"
#set -x
set -e    # fail if an error is hit so that errors do not go unnoticed

site=$SITE

##  determine system/phase

module purge

##   On phase 3 with Lua Modules, loading prod_util without preloading 
##   dependent modules will fail.  This means that we need to know the 
##   system in order to be able to run the getsystems.pl utility so as 
##   to determine the system.
##   To overcome this circular logic, use hostname to do special loading 
##   of the prod_util module so as to run the getsystems.pl utility.

hname=$(hostname)
if [[ $hname =~ ^[vmp][0-9] ]] ; then # Dell-p3: venus mars pluto
  module load ips/18.0.1.163
  module load prod_util/1.1.0

else
  ## On non-phase 3 systems, can simply load prod_util directly

  module load prod_util               # non-Lua Modules system
fi # if hname starts w/ [vmp][digit]

sys_tp=$(getsystem.pl -tp)
echo "build: running on $sys_tp ($site)"

#echo "db exit" ; exit

module purge

case $sys_tp in
Cray-XC40)
 module load PrgEnv-intel;
 module load craype-sandybridge;
 module swap intel/16.3.210;
 lib_build="intel";
 export FC=ftn;
 ;;
IBM-p1|IBM-p2)
 module load ics/12.1;
 module load ibmpe;
 ;;
Dell-p3)
 module load ips/18.0.1.163 ;    # req'd for bufr
 module load impi/18.0.1    ;    # req'd for w3emc
 ;;
*) echo "build: unexpected system.  Update for $sys_tp ($site)";
   echo "build: exiting" ; exit 99 ;;
esac

source ./load_libs.rc  # use modules to set library related environment variables

module list

if [ $# -eq 0 ]; then
  dir_list=*.fd
else
  dir_list=$*
fi
echo "build: list of dirs to build:"
echo $dir_list

#echo "db exit" ; exit

clobber=${clobber:-clobber_yes}  # user can override the default of running "make clobber"
for sdir in $dir_list; do
 echo 
 dir=${sdir%\/}  # chop trailing slash if necessary
 echo "build: making ${dir%\.fd*}"
 cd $dir
 [ $clobber != clobber_no ]  && make clobber
 if [ $sys_tp = Cray-XC40 ]; then
   make FC=$FC
 else
   make
 fi
 ###touch *
 ls -l
 cd ..
done

echo "build: end of obsproc_global build script"
