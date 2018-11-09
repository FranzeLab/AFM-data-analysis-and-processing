#!/bin/bash
. /etc/profile.d/modules.sh                # Leave this line
module purge                               # Removes all modules loaded by ~/.bashrc
module load matlab                   # REQUIRED - loads the basic environment
                                           # for Intel MPI/Intel compilers;


cd /home/em429/



matlab -nodisplay -nojvm -r "try;path(path,'/home/em429/'); RUN_ON_DARWIN ('/home/em429/S1'); catch;end;quit" &
matlab -nodisplay -nojvm -r "try;path(path,'/home/em429/'); RUN_ON_DARWIN ('/home/em429/S2'); catch;end;quit" &
matlab -nodisplay -nojvm -r "try;path(path,'/home/em429/'); RUN_ON_DARWIN ('/home/em429/S3'); catch;end;quit" &


  

wait
echo "hello world!!"
