#!/bin/bash

# bash recursive_interactive_llava_eval.sh
export SLURM_OVERLAP=1   # makes every srun step (including the ones inside eval.sh) overlap

while true; do
  salloc --nodes=1 --time=1:00:00 --gpus-per-node=1 --ntasks-per-node=1 -p debug \
         --mail-user=rohollah903@gmail.com --mail-type=ALL \
    srun --overlap bash -c '
      start=$SECONDS
      k=128
      kmin=20
      timeout -k 60 55m bash bash ${PROJECTS_DIR}/AnchorPrune/scripts/eval_llava_1_5_refcoco.sh --k $k --kmin $kmin 2>&1 | tee "$SLURM_OUTPUTS/AnchorPrune_llava_k${k}_kmin${kmin}_refcoco,refcoco+,refcocog.log" 2>&1
      [ $((SECONDS - start)) -lt 3000 ] && exit 0 || exit 100
    '
  [ $? -eq 100 ] || break
done