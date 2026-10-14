#!/bin/bash
K=64; KMIN=1; TASKS=refcoco,refcoco+,refcocog

while [[ $# -gt 0 ]]; do
  case $1 in
    --k) K="$2"; shift 2 ;;
    --km|--kmin) KMIN="$2"; shift 2 ;;
    --t|--tasks) TASKS="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

export K KMIN TASKS
export LOG="$SLURM_OUTPUTS/AnchorPrune_k${K}_kmin${KMIN}_${TASKS//,/_}.log"

while true; do
  salloc --time=2:00:00 --nodes=1 --mem=256G --gres=gpu:h100:4 \
         --ntasks-per-node=1 --cpus-per-task=8 \
         --mail-user=rohollah903@gmail.com --mail-type=ALL \
    srun --ntasks=1 --input=none bash -c '
      start=$SECONDS
      export PYTHONUNBUFFERED=1 NCCL_DEBUG=WARN
      echo "GPUs: $CUDA_VISIBLE_DEVICES"; nvidia-smi -L
      timeout -k 60 115m bash "${PROJECTS_DIR}/AnchorPrune/scripts/eval_qwen2_5_vl_refcoco.sh" \
          --k "$K" --kmin "$KMIN" --tasks "$TASKS" 2>&1 | tee -a "$LOG"
      [ $((SECONDS - start)) -lt 6600 ] && exit 0 || exit 100
    '
  [ $? -eq 100 ] || break
done