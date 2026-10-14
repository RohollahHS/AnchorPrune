#!/bin/bash
# recursive_interactive_eval.sh  (run inside tmux/screen on the login node)

K="64"
KMIN="1"
TASKS=refcoco,refcoco+,refcocog

while [[ $# -gt 0 ]]; do
  case $1 in
    --k)
      K="$2"
      shift 2
      ;;
    --km|--kmin)
      KMIN="$2"
      shift 2
      ;;
    --t|--tasks)
      TASKS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

while true; do
  salloc --time=2:00:00 --nodes=1 --mem=256G --gres=gpu:h100:4 \
         --ntasks-per-node=1 --cpus-per-task=8 \
         --mail-user=rohollah903@gmail.com --mail-type=ALL \
    srun bash -c --overlap '
      start=$SECONDS
      timeout -k 60 115m bash bash ${PROJECTS_DIR}/AnchorPrune/scripts/eval_qwen2_5_vl_refcoco.sh --k 64 --km 1 --tasks refcoco,refcoco+,refcocog --k 128 --kmin 20 2>&1 | tee "$SLURM_OUTPUTS/AnchorPrune_k${k}_kmin${kmin}_refcoco,refcoco+,refcocog.log"
      # ran < 1:50:00 (6600s) -> finished (or failed early) -> exit 0
      # ran >= 1:50:00        -> was cut off -> exit 100 to resubmit
      [ $((SECONDS - start)) -lt 6600 ] && exit 0 || exit 100
    '
  [ $? -eq 100 ] || break
done