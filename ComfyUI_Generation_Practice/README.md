# SDXL・Z-Image・MiniMax H3 練習ドキュメント

既存PC環境で作成・検証した学習用ドキュメントを集めたものです。2026-10-01時点のコピーで、原本は変更していません。

## 読む順序

1. [SDXL学習パック](SDXL/README.md): Seed固定でCFG・Steps・Samplerを比較し、img2img、Inpaint、HiRes、ControlNet、LoRA、IPAdapterへ進む。
2. [Z-Image学習パック](Z-Image/README.md): モデル・encoder・VAEの構成を確認し、基本生成、LoRA、画像編集、アップスケール、ControlNet、Base/Turboの比較へ進む。実際のLoRA学習ツールは未導入。
3. [MiniMax H3学習環境](MiniMax-H3/README.md): Phase 1〜9のT2V、Draft/768p、I2V、First/Last、Reference、ControlNet、長尺化、メモリと高速化の実測を読む。

SDXL/Z-Imageの静止画をH3のFirst Frameへ渡す練習につなげられます。比較時はPromptとSeedを固定し、変更する設定を1項目に絞り、設定・生成時間・結果・気づきを記録してください。

## このフォルダーと原本の関係

ここには文章だけをコピーしています。モデル・workflow JSON・生成動画は元のWindows環境にあり、コピー先へは移していません。各READMEの相対パス（input/、output/、workflows/など）は、それぞれの元のComfyUI環境を基準に読んでください。

| 対象 | ドキュメント原本（Windows） | 実行・素材の基準フォルダー |
|---|---|---|
| SDXL | `C:\Users\uekus\Documents\comfyui\user\default\workflows\SDXL_learning_pack\README.md` | `C:\Users\uekus\Documents\comfyui` |
| Z-Image | `C:\Users\uekus\Documents\comfyui\user\default\workflows\Z_Image_learning_pack\README.md` | `C:\Users\uekus\Documents\comfyui` |
| MiniMax H3 | `C:\Users\uekus\Documents\comfyui-h3\README.md` | 環境: `C:\Users\uekus\Documents\comfyui-h3`、素材・動画: その下の`ComfyUI` |

取得元、容量、SHA256を `sources.json` に記録し、コピーの一致を確認済みです。自動同期は行いません。後日環境や原本を更新した場合は、このコピーも更新してください。
