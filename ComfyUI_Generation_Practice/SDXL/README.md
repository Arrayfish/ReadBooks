# SDXL / ComfyUI 学習パック

## 実行順

1. `01_KSampler_baseline.json` — Seedを固定し、CFG / Steps / Samplerを1項目ずつ変える。
2. `02_img2img_denoise.json` — `denoise` を 0.1 / 0.3 / 0.5 / 0.7 / 1.0 で比較。
3. `03_inpaint_mask.json` — 白いMask部分だけを再生成。
4. `04_upscale_vs_hires.json` — 単純拡大と、低denoise再描画を比較。
5. `05A_ControlNet_Canny_READY.json` / `05B_ControlNet_OpenPose_READY.json` / `05C_ControlNet_Depth_READY.json` — 構図・ポーズ・奥行きを制御する。
6. `06_LoRA_strength.json` — Seed固定でLoRA強度だけ変える。
7. `07_IPAdapter_SDXL_Plus_READY.json` — 参照画像の作風・色・雰囲気を引き継ぐ。
8. `08_production_explore.json` — Seed探索用。良い画像を2→3→4へ送る。

## 自動生成した入力

- `input/learning/01_baseline.png` — img2img / inpaint / HiResの共通元画像
- `input/learning/03_center_mask.png` — Inpaint用マスク（白を描き直す）

## 生成済み比較画像

- `output/SDXL_learning/comparison_stage1.png` — CFG / Steps / Sampler比較
- `output/SDXL_learning/comparison_pipeline.png` — baseline → img2img → Inpaint → HiRes → LoRA
- `output/SDXL_learning/comparison_controlnet.png` — Canny / OpenPose / Depth比較
- `output/SDXL_learning/05_controlnet/canny_00001_.png` — Canny ControlNet実行例
- `output/SDXL_learning/07_ipadapter/reference_065_00001_.png` — IPAdapter Plus実行例
- 個別画像は `output/SDXL_learning/01_ksampler` 〜 `06_lora` に保存
- 失敗した広すぎるInpaintマスク例は `_rejected_inpaint_attempts` に隔離（教材用の本採用は `pocket_crane_00002_.png`）

## 導入済み追加モデル

- Xinsir SDXL ControlNet: OpenPose / Depth / Canny V2
- Comfy.org `comfyui-ipadapter` ノード
- SDXL IPAdapter Plus ViT-H
- CLIP Vision ViT-H
- DWPose / Depth Anything V2 前処理モデル（初回実行で取得済み）

`Qwen-Image-InstantX-ControlNet-Inpainting.safetensors` はQwen系なので、Juggernaut XLへは接続しないこと。AIアップスケールモデルは未導入のため、Stage 4はLanczosとHiResを比較する。
