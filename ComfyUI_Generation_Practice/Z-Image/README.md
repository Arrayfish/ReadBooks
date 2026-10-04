# Z-Image / ComfyUI 学習パック

このフォルダは、添付の学習計画を現在のPC環境に合わせて実行可能なComfyUIワークフローへ落とし込んだものです。

## 推奨順序

1. `00_architecture_map.json` — UNET / Qwenテキストエンコーダ / VAE / latent / sampler の流れを追う。
2. `01A`〜`01C` — prompt・seed・縦横比を比較する。まず1項目だけ変える。
3. `02_LoRA_strength_pixel_art.json` — Pixel Art LoRAを0 / 0.4 / 0.8 / 1.0で比較する。
4. `03_img2img_denoise.json` — denoise 0.15 / 0.35 / 0.55 を比較する。
5. `04_masked_edit.json` — 白いmask範囲だけを描き直す。
6. `05_HiRes_RealESRGAN.json` — RealESRGANと低denoise再描画を比較する。
7. `06A`〜`06C` — Z-Image Fun ControlNet UnionでCanny / OpenPose / Depthを試す。
8. `07A`〜`07B` — BaseのCFG／Negative、Turbo対Baseを比較する。
9. `08A`〜`08D` — 高速探索・制御付き生成・mask編集・仕上げの実務4本。
10. `09_LoRA_training_plan.json` — 任意の学習段階のチェックリスト。

## 現在の環境で実行可能

- Turbo基本生成、LoRA、img2img、mask編集、RealESRGAN + HiRes、Canny/OpenPose/Depth ControlNet、Z-Image Base
- 使用モデル: `z_image_turbo_bf16.safetensors`, `qwen_3_4b.safetensors`, `ae.safetensors`
- ControlNet: `Z-Image-Turbo-Fun-Controlnet-Union.safetensors`
- Base: `z_image_bf16.safetensors`
- LoRA: `pixel_art_style_z_image_turbo.safetensors`（trigger: `Pixel art style.`）
- Upscaler: `RealESRGAN_x4plus.safetensors`

## 追加導入が残るもの

- Stage 9の実際の学習を行う場合のみ、Base対応のLoRA学習ツールチェーンが必要。
- Z-Image専用の公式Editチェックポイントは使わず、Stage 4/8Cはimg2img + maskで実行する。

## 動作確認済みの生成例

- `output/Z_Image_learning/01_basic/baseline_00001_.png`
- `output/Z_Image_learning/02_lora/pixel_art_test_00001_.png`
- `output/Z_Image_learning/03_img2img/denoise_035_00001_.png`
- `output/Z_Image_learning/04_masked_edit/crane_patch_00001_.png`
- `output/Z_Image_learning/05_hires/refined_00001_.png`
- `output/Z_Image_learning/05_hires/realesrgan_1536_test_00001_.png`
- `output/Z_Image_learning/06_controlnet/canny_00001_.png`
- `output/Z_Image_learning/07_base/base_cfg4_test_00001_.png`

共通入力は `input/z_image_learning/01_baseline.png`、白黒maskは `input/z_image_learning/04_center_mask.png` です。

Turboは公式ComfyUI構成に合わせ、8 steps / CFG 1 / `res_multistep` / `simple` / zero conditioningを初期値にしています。
