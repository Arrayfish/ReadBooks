# MiniMax H3 学習環境 — Phase 1〜9

2026-09-30調査。Phase 1の最小Text-to-Audio-Video、Phase 2のTurbo Draft、Phase 3の768p標準品質、Phase 4のFirst Frame I2V、Phase 5のFirst/Last条件比較、Phase 6の画像・動画・音声Referenceを実機で検証済み。
2026-10-01: Phase 7のPose / Depth / Canny、Phase 8の10〜30秒連続生成、Phase 9の15条件比較を完了。14条件成功、split attentionはOOMを記録。詳細と制約は各フェーズの節を参照。
Phase 6の完了確認は2026-10-01（日本時間）。開始時の公式情報調査は2026-09-30。
Phase 1の記録は `latest_measurement.json` と `measurements/`、Phase 2は `latest_phase2_8step.json`, `latest_phase2_4step.json`, `measurements/phase2/` に保存。

## 環境と分離

- 専用フォルダー: `C:\Users\uekus\Documents\comfyui-h3`
- 専用Python: `.venv\Scripts\python.exe` (Python 3.12.11)
- ComfyUI: 0.38.0、公式GitHub、コミット `8cfe5e1ecb97512dea8deaac15e1228d7e6feeb1`
- PyTorch 2.11.0+cu130、torchvision 0.26.0+cu130、torchaudio 2.11.0+cu130
- RTX 5070のSM120とBF16行列積を実機で確認済み。
- ComfyUI requirementsの依存関係。最終一覧は `requirements-lock.txt`。
- 通常のH3 / ControlNet / Pose / Depth / Canny / 長尺化は標準ノードだけで構成。Phase 9のGGUF比較に限り `leejet/ComfyUI-GGUF` を専用環境へ追加し、比較用起動でそのフォルダーだけを許可する。通常起動は引き続き全custom nodesを無効化する。
- 既存Desktopのコード、`Documents\comfyui\.venv`、SDXL/Z-Imageモデル・workflow・custom nodesを更新しない。
- Driver、CUDA Toolkit、pagefile、Windowsセキュリティ設定は変更しない。

既存環境: ComfyUI 0.37.0、コミット `b0f4b7b294ce482a2e071d9d762c133d38c7aa07`、Python 3.12.11、torch 2.8.0+cu129。
custom nodesは `comfyui_controlnet_aux`, `ComfyUI-Florence2`, `comfyui-ipadapter`。
既存ログにはextra-path設定のパスが空白で分断された起動失敗がある。過去ログの記録であり、現在のDesktop全体が故障していると判断するものではない。

## PC調査

Windows 11 Home、Ryzen 7 9700X、RAM約61.65GiB可視、GPU VRAM 12227MiB、NVIDIA Driver 617.14。
`nvidia-smi`のCUDA UMD 13.4はドライバーの対応表示。PyTorch実行時のCUDA 13.0とは区別する。
CUDA Toolkitの `nvcc` はPATH上では見つからない。公式PyTorch wheelでの推論にToolkitの別途導入は不要。
Git 2.52.0.windows.1。通常の `python` はWindows Store aliasであり、専用環境では実体への絶対パスを使う。
Cドライブ空き容量は調査時256.84GB（239.20GiB）。pagefileは自動管理、調査時割り当て3968MiB。
詳細は `pc_audit.json`。アプリによるGPU占有約2.6GiBも初期状態に含まれる。

## モデル

配布元: https://huggingface.co/Comfy-Org/MiniMax-H3
モデルrevision・正確なbyte数・SHA256は `model_manifest.json`、検証完了後は `models_verified.json` に記録する。
サイズは十進GB。

| 保存先（ComfyUI/models配下） | モデル | GB | 役割 |
|---|---|---:|---|
| diffusion_models | minimax_h3_fl2va_pruned_int8_convrot.safetensors | 20.970 | T2V / First / LastのH3 Transformer |
| text_encoders | qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors | 15.687 | テキスト・画像の意味をconditioningへ変換 |
| vae | minimax_h3_video_vae_fp16.safetensors | 5.208 | 動画latentと画素の変換 |
| vae | minimax_h3_audio_vae_fp32.safetensors | 0.605 | 音声latentと32kHz stereo波形の変換 |
| loras | minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors | 1.956 | Phase 2: FL2VA向けTurbo、4/8 stepsの蒸留LoRA |
| diffusion_models | minimax_h3_ref2va_pruned_int8_convrot.safetensors | 20.970 | Phase 6: image/video/audio reference用Ref2VA Transformer |
| loras | minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors | 1.956 | Phase 6: Ref2VA向けTurbo 4 steps |

Phase 1の4モデルは合計42.471GB。Phase 2の追加LoRAを含め44.427GB、Phase 6の2モデル追加後は67.353GB。元のMiniMax BF16の全リポジトリはダウンロードしない。
Turboの開発元はModelTC/lightx2v、取得先は上記Comfy-OrgのComfyUI版ミラー。`phase2_model_manifest.json` に追加モデルのbyte数・SHA256・取得URL・revisionを記録し、全5モデルのSHA256を検証済み。
Phase 6は追加22.926572616GB。`phase6_model_manifest.json` / `phase6_models_verified.json` にRef2VA本体と専用LoRAのサイズ・SHA256・repo・revisionを別記録し、両ファイルを照合済み。保存先は上表の専用 `ComfyUI/models` 配下。
Phase 6もモデルrevision `e5eb578a89295337b8ff433a035929ce0279e0b6`。encoderと2つのVAEは再利用し、FL2VA本体とLoRAは残す。
Comfy-OrgによるComfyUI向け再梱包・量子化であり、MiniMaxのオリジナルBF16とは区別する。
最近の公式テンプレートはINT8 video VAEを使用するが、今回はFP16 VAEを分割デコードして初期の変数を減らす。

## 選択肢を比較した理由

FL2VAは量子化方式ではなくタスクの種類。入力画像なしでT2V、1枚でFirstまたはLast、2枚でFirst+Lastになる。
pruned INT8 ConvRotは本体のネイティブローダーで処理でき、Comfy-OrgはCUDA 13.0環境でこの形式を推奨する。
NVFP4/AWQ encoderはComfy-Orgの標準CLIPLoaderで利用する。encoderも15.7GBあるので12GBに全量常駐させない。
NVFP4のファイル保存精度と、実際の計算dtypeやカーネル、offloadは別の概念。
64GB RAMを利用し、DiT・encoder・VAEを段階的にロードする。全モデルのサイズ合計がVRAMに収まる必要はない。
ただしRAM上の展開、作業領域、転送バッファも必要なので、ファイル合計だけでは成功を保証できない。

GGUF Q3/Q4はUnsloth等に存在する。Unsloth pruned FL2VAはQ3_K約8.16GiB、Q4_K約10.64GiB。
ComfyUIではGGUFローダーのH3対応やencoderのmultimodal処理を追加検証する必要があり、最初は標準ローダーのINT8で基準を作る。
GGUF形式は本体のUNETLoaderへそのまま入れられない。GGUF同士でも量子化方式・pruning・encoder sidecarによって互換性が異なる。
Q2、INT4 DiT、encoderを別の小型モデルへ蒸留・置換する方式はPhase 1で採用しない。
INT8での失敗時にはencoder、DiT sampling、VAE decodeのどこが不足したかを調べ、offloadや解像度を先に調整する。

## 起動

PowerShellで次を実行する。ExecutionPolicyは変更しない。

```powershell
& 'C:\Users\uekus\Documents\comfyui-h3\start_h3.ps1'
```

もしローカルスクリプト実行がWindowsの設定で拒否される場合、次を直接入力する。

```powershell
Set-Location 'C:\Users\uekus\Documents\comfyui-h3\ComfyUI'
& '..\.venv\Scripts\python.exe' main.py --listen 127.0.0.1 --port 8190 --disable-all-custom-nodes --use-pytorch-cross-attention --reserve-vram 2 --disable-fast-disk --disable-pinned-memory --disable-comfy-compiler --async-offload 1 --cache-none
```

UI: http://127.0.0.1:8190
終了は起動したターミナルでCtrl+C。既存Desktopと同時に生成するとGPU/RAMを奪い合うため、同時キュー実行は避ける。
localhostの別ポートを使用するため外部公開しない。

## Phase 1 workflow

`workflows/00_H3_T2V_Phase1.json` はUI用。ComfyUIへドラッグ&ドロップして読み込める。
専用UIの `user/default/workflows/H3_Learning/` にも同じworkflowを保存する。
`00_H3_T2V_Phase1_api.json` はAPI実行用でUI用JSONと区別する。
`official_t2v.json` は調査時に取得した公式テンプレートの原本。

初期設定: 608×352、124フレーム、24fps、約5.17秒、20 steps、seed 50709700、res_multistep / simple。
低解像度で標準経路の動作を確認するための設定。Turboやcacheを含むPhase 2 Draftではない。
H3のフレーム数は17k+5に調整される。5秒ちょうどの120フレームではなく124フレームが近い有効値。
モデルの主な学習解像度は768pで、低解像度の画質は標準品質の判断には使わない。

| ID / ノード | 入力 → 出力 | なぜ必要か |
|---|---|---|
| 1 UNETLoader | INT8ファイル → MODEL | H3 Transformerの重み。名前はUNETLoaderでもH3はTransformer |
| 2 CLIPLoader | H3用Qwen3-VL encoder → CLIP | CLIP型はComfyUIのインターフェース名で、今回の実体はQwen3-VL |
| 3 VAELoader | video VAE → VAE | latentを動画へ戻す |
| 4 VAELoader | audio VAE → VAE | latentをステレオ音声へ戻す |
| 5 MiniMaxH3ImageToVideo | Prompt・encoder・サイズ・フレーム数 → conditioning + 空AV latent | encoderの隠れ状態をH3向け条件にし、生成する形を定義。First/Last未接続ならT2V |
| 6 RandomNoise | Seed → NOISE | 生成の初期乱数を再現する |
| 7 KSamplerSelect | res_multistep → SAMPLER | ノイズ除去の数値解法を選ぶ |
| 8 BasicScheduler | MODEL・steps・scheduler → SIGMAS | 各stepのノイズ量を指定 |
| 9 BasicGuider | MODEL + conditioning → GUIDER | H3へ条件を渡す。CFG-distilledモデルなので通常のCFG二重計算を行わない |
| 10 SamplerCustomAdvanced | noise・guider・sampler・sigmas・AV latent → 生成AV latent | Transformerを繰り返し呼び、動画と音声を同時に生成 |
| 11 VAEDecodeTiled | AV latentの動画成分 + video VAE → IMAGE batch | 時間・空間を分割してVRAMを抑える |
| 12 VAEDecodeAudio | AV latentの音声成分 + audio VAE → AUDIO | 音声波形を復元 |
| 13 CreateVideo | IMAGE batch・24fps・AUDIO → VIDEO | 画面と音声をまとめる |
| 14 SaveVideo | VIDEO → MP4ファイル | `ComfyUI/output/phase1/`へ保存 |

データフロー:

```text
Prompt → Text/Multimodal Encoder → conditioning ────┐
Seed → noise                                      │
Resolution/frames → empty video/audio latent       ├→ H3 Transformer (sampling)
Steps → sigmas                                    │     ↓
                                                   ┘  video/audio latent
                                                      ├→ Video VAE → frames ─┐
                                                      └→ Audio VAE → audio ──┴→ MP4
```

変更箇所: Prompt/Resolution/Frame countはID5、SeedはID6、StepsはID8。
Phase 1では画像入力の実験、Ref2VA、ControlNet、長尺化をまだ実行しない。

## メモリ設定と計測

DynamicVRAMとasync offloadを利用し、`--disable-fast-disk`でRAMへのoffloadを優先する。
実機では既定のpinned memory等でコミット上限に近づいたため、pinned memory、Comfy compiler、ノードキャッシュを無効化し、async offloadは1 streamにする。
これらは専用プロセス内の設定で、Windowsのpagefileやセキュリティ設定を変更するものではない。
キャッシュ無効のため毎回encoderを再実行する。まず安定して動く基準を優先し、速度との比較は後続Phaseで行う。
`--reserve-vram 2`でOS等の余地を設定する。現在のDynamicVRAMでは `--lowvram` が効かないため、古い起動例をそのまま使わない。
標準PyTorch attentionを使う。SageAttention、FlashAttention、Triton、cache、compilerは後続Phaseの比較対象。
動画VAEはtile_size=256、overlap=64、temporal_size=32、temporal_overlap=8。

`measure_generation.py` は専用サーバーのPIDを `server_pid.txt` から読み、API workflowをキューに送り計測する。
約1秒間隔のCSV、ComfyUI history、summaryを `measurements/` に保存。
生成時間は初回のモデルロード、encoder、sampling、VAE decode、MP4保存を含み、インストールやダウンロードは含まない。
GPU値はnvidia-smiのGPU全体であり、デスクトップや他アプリを含む。PyTorchのallocatorピークとは別。
RAMは専用サーバーのプロセスツリーRSS、private commit、PC全体の物理RAM使用量を別々に記録する。
サンプリング計測なので瞬間的なピークを取り逃す可能性がある。
モデルファイルのメモリマップやOSのファイルキャッシュも利用されるので、プロセスRSSだけがCPU側モデル全体の容量ではない。private commit、全体の物理使用量、コミット量を併記する。
物理RAM残り2GiB未満、またはコミット上限の97%を超えた場合、計測器は生成のinterruptを要求する。

## トラブルシューティング

- CUDA / sm_120: 専用pythonでtorchのCUDA版とarchitectureを確認。既存venvのtorchを更新しない。
- INT8 kernel: Comfy-Orgはcu130を推奨。cu129の既存環境とは分離する。
- encoderでOOM: DiTより先の段階。Prompt長・GPUの他アプリ占有・offloadを確認する。
- samplingでOOM: 解像度・フレーム数・DynamicVRAM headroomとRAM/commitを確認する。
- VAEでOOM: temporal_sizeやtile_sizeを下げる。生成モデルの量子化変更だけではdecodeの不足を解決できない。
- RAM / commit不足: CSVとWindowsのコミット量を確認。pagefileの変更はシステム設定なので説明・確認してから行う。
- モデル一覧に見えない: 配置先・拡張子・SHA256検証を確認して専用サーバーを再起動する。`.part`は未完了ファイル。
- attention wheelのDLLエラー: torch/CUDA/Python/SM120との組合せを確認。Phase 1は追加wheelが不要な標準attention。
- ポート競合: 8190の利用者を確認。既存サーバーを無断終了しない。

## Phase 1 実測結果

同じモデル・seed・608×352・124フレーム・24fps・20 steps。解像度や量子化を下げず、専用サーバーを再起動して設定だけ変更した。

| 項目 | 初回（中断） | 設定変更後（成功） |
|---|---:|---:|
| 実行時間 | 27.08秒で中断 | 105.025秒（API計測105.547秒） |
| sampling | 初期化時に中断 | 20 steps、約73秒、約3.66秒/step |
| peak GPU全体 | 10879MiB / 10.62GiB | 11526MiB / 11.26GiB |
| peak server process-tree RSS | 36.63GiB | 5.88GiB |
| peak server private commit | 45.83GiB | 16.40GiB |
| peak PC物理RAM使用量 | 54.60GiB | 24.39GiB |
| peak PCコミット量 | 66.74GiB | 37.19GiB |
| 最小PC空き物理RAM | 7.05GiB | 37.26GiB |
| 結果 | コミット上限67.54GiBに接近、計測器がinterrupt | MP4保存成功、OOMなし |

成功試行は `079cc3a3-bf93-434e-a9af-0598612d69ab`。開始時GPU使用量1344MiB、PC物理RAM使用量17.16GiB。
初回はpinned memory・compiler・RAM pressure cache・2 streams。成功時はpinned memory無効・compiler無効・cache-none・1 stream。
複数設定をまとめて変更したため、各設定の個別寄与は未測定。Phase 9の比較で切り分ける。
pagefileは自動管理のままで、OSが初回試行中にコミット上限を少し拡張していた。手動変更は行っていない。

生成物: `ComfyUI/output/phase1/H3_T2V_Phase1_00001_.mp4`、604991 bytes。
H.264 608×352、24fps、124フレーム、5.166667秒。AAC 32kHz・2ch、5.166688秒。全フレームと音声をPyAVでデコードできた。
音声は無音ではなく、デコード波形のRMS約0.00382、peak約0.0393。内容や聴感上の同期品質はユーザーの再生確認対象。
`phase1_contact_sheet.jpg` に6つの代表フレーム、`output_inspection.json` にストリーム検証を保存。
目視では夕焼け色の湖面とヨットが連続して描かれ、船体・帆・反射に大きな破綻や黒フレームは見られない。Promptの「小さな赤い船」など細部の一致は完全ではない。
これは低解像度の動作検証で、768p品質や複雑な人物動作、identity保持を保証する結果ではない。

## 導入中に起きた問題

HFのencoder転送がタイムアウト。取得済み部分から再開し、最後にSHA256を照合した。
動画VAEは取得済みprefixを保持して範囲指定の並列ダウンロードへ切り替え、サイズとSHA256の両方で検証した。
`video_vae_download_progress.json` は取得記録であり、モデル本体ではない。
モデル取得前の事前検証ログには「model not in list」がある。実行前には全モデルが一覧に載り、実際のAPI検証・生成が成功した。
初回のメモリ中断記録は `measurements/` に残してあり、成功だけを記録したものではない。

## 更新方法

基準環境を再現できるようcommit、依存ロック、モデルmanifest、workflowと計測ログを残す。
更新前に専用ComfyUIの `git status --short`、commit、`pip freeze` を保存し、別コピー/別venvで検証する。
最新公式documentation・requirements・Blackwellの問題を確認し、固定したモデルとworkflowで再生成・比較してから切り替える。
既存Desktop側へのgit pull/pip upgradeや全custom nodes一括更新は行わない。

## Phase 2 Draft workflowと実測

専用ComfyUIのワークフロー一覧を更新し、`H3_Learning`から開くか、以下のUI用JSONをドラッグ&ドロップする。

- `workflows/01_H3_T2V_Draft.json`: 推奨の8 steps、品質と速度の基準。
- `workflows/01_H3_T2V_Draft_4step.json`: 4 steps、構図・動きの試行用。
- 同名の `_api.json` は計測・API用であり、UI用とは区別する。

共通設定: 864×480 = 0.41472MP、124フレーム、24fps、5.1667秒。seed 50709700、Euler / simple、LoRA strength 1.0、video/audio sigma shift 12/3。
開発元のFL2VA 8step v1.0（544p向け）の推奨4/8 NFE・shift 12/3を採用。今回の0.415MPは低解像度Draftの実験であり、544pや768pの品質検証ではない。
別の768p Turboは異なるLoRAとshiftを必要とするため、今回の12/3設定をそのまま流用しない。
既存のINT8 Transformer、encoder、VAE、専用offload設定を継続。custom node・追加Pythonパッケージ・システム設定の変更はない。

Phase 1から追加・変更したノード:

| ID / ノード | 入力 → 出力 | なぜ必要か |
|---|---|---|
| 16 LoraLoaderModelOnly | INT8 H3 MODEL + Turbo LoRA + strength → MODEL | 蒸留された差分重みを適用し、少ないstepsで生成できるようにする。INT8保存モデルにBF16 LoRAの208 patchesを実際に適用できた |
| 17 MiniMaxH3SigmaShift | Turbo MODEL + video/audio shift → MODEL | 動画・音声のノイズスケジュールを学習時の推奨値12/3へ設定。接続先はID8とID9の両方 |
| 7 KSamplerSelect | Euler → SAMPLER | Turboの推奨数値解法 |
| 8 BasicScheduler | ID17 MODEL + simple + 4/8 steps → SIGMAS | Turbo用のノイズ量を生成 |
| 9 BasicGuider | ID17 MODEL + ID5 conditioning → GUIDER | Turboとshiftを適用したH3に同じconditioningを渡す |

データ経路はPhase 1の表を参照。MODELだけが `INT8 H3 → Turbo LoRA → SigmaShift → Scheduler / Guider` に変わる。
Prompt・解像度・フレーム数はID5、SeedはID6、StepsはID8、fpsはID13。First/Last画像端子は未接続のままT2Vとして使う。
出力は `ComfyUI/output/phase2/`。4-step版はファイルprefixも分けている。

### RTX 5070の比較結果

同じPrompt・Seed・解像度・フレーム数で各1回。各試行前にモデルをunloadし、ノードキャッシュは無効。
同じサーバープロセスを利用するため、OSファイルキャッシュなどの影響は除去していない。時間はComfyUIの実行開始〜成功の記録を採用。

| 項目 | 8 steps | 4 steps |
|---|---:|---:|
| 生成時間 | 104.711秒 | 63.462秒 |
| API全体時間 | 105.250秒 | 64.265秒 |
| sampling（ログ、概数） | 80秒 | 40秒 |
| peak GPU全体 | 11516MiB / 11.25GiB | 11429MiB / 11.16GiB |
| peak server RSS | 6.35GiB | 6.34GiB |
| peak server private commit | 16.67GiB | 16.46GiB |
| peak PC物理RAM使用量 | 25.32GiB | 26.51GiB |
| peak PCコミット量 | 33.62GiB | 33.48GiB |
| 最小空き物理RAM | 36.33GiB | 35.14GiB |
| 安定性 | OOMなし・保存成功 | OOMなし・保存成功 |

この2試行では4 stepsは8 stepsより約39.4%短時間。少ないstepsにしてもピークVRAM/RAMは大きく減らない。
Phase 1の608×352・20 stepsとPhase 2の864×480は画素数が異なるので、Phase 1との時間比較からTurbo単独の速度倍率は算出しない。
8 stepsでは帆・船体・反射が連続し、代表フレームに大きな破綻は見られない。4 stepsも形状を維持するが、代表フレームでは帆の模様や輪郭などの細部が8 stepsより簡略に見える。いずれも赤色指定の一致は弱い。
これは1つの単純な場面の目視評価。人物・複雑な動作・他Seedの品質と長時間安定性は未検証。まず8 stepsを基準とし、速い試行には4-step版を使う。

両MP4はH.264 864×480、124フレーム、24fps、5.166667秒、AAC 32kHz stereo 5.166688秒。全動画フレーム・音声をPyAVでデコード済み。
音声は非ゼロ（8 steps RMS 0.00135 / peak 0.0158、4 steps RMS 0.000782 / peak 0.00616）。聴感や内容・同期の評価は未実施。
動画は `H3_T2V_Draft_8step_00001_.mp4` と `H3_T2V_Draft_4step_00001_.mp4`。
`phase2_8step_contact_sheet.jpg`, `phase2_4step_contact_sheet.jpg`、対応する `_inspection.json`、`measurements/phase2/benchmarks.csv` に検証結果を保存。
ComfyUIの画面でも8-step版を開き、Promptと説明ノートが表示されることを確認済み。

再計測例（計測器のPID記録は、現在の専用サーバーと一致させる）:

```powershell
& 'C:\Users\uekus\Documents\comfyui-h3\.venv\Scripts\python.exe' 'C:\Users\uekus\Documents\comfyui-h3\measure_generation.py' --workflow 'C:\Users\uekus\Documents\comfyui-h3\workflows\01_H3_T2V_Draft.json' --results 'C:\Users\uekus\Documents\comfyui-h3\measurements\phase2' --latest 'C:\Users\uekus\Documents\comfyui-h3\latest_phase2_8step.json' --label draft8
```

LoRAが一覧にない場合は `models/loras` のファイル名・SHA256を確認し、モデル一覧を更新する。Turboで画面が崩れる場合はstepsだけでなく、LoRAのFL2VA/Ref2VA・解像度系統・versionとsigma shiftの組合せを確認する。

## Phase 3 Standard workflow

`workflows/02_H3_T2V_Quality.json` はUI用。専用UIの `H3_Learning`にも保存。
同名の `_api.json` はAPI計測用。`build_quality_workflow.py` で再構築できる。

設定: 1344×768（1.032192MP）・124フレーム・24fps・約5.17秒・20 steps・res_multistep / simple。
Promptとseed 50709700はPhase 1/2と同じヨットの場面。公式ネイティブガイドの768p・20 stepsに合わせ、Turbo LoRAは接続しない。
Phase 2の544p向けTurbo LoRAを768pへ流用せず、基準品質の本体モデルを使う。
モデルは既存のpruned INT8 ConvRot / NVFP4 AWQ encoder / FP16 video VAE / FP32 audio VAEを再利用。追加ダウンロード・custom node・依存更新・Windows設定変更は不要。
専用ComfyUIのcommitとoffload起動設定はPhase 1/2から変更していない。

ノードID1〜14と役割はPhase 1の表に一致する。Prompt・解像度・フレーム数はID5、seedはID6、stepsはID8、fpsはID13。
`INT8 H3 → Scheduler / Guider`へ直接つなぎ、Phase 2で使ったLoRAとSigmaShiftノードは含めない。
本体のH3標準sampling設定はvideo shift 12 / audio shift 3（固定commitの `comfy/supported_models.py` で確認）。Turboの別モデルで指定されるshiftとは区別する。
高解像度では空latentの空間サイズが増え、Transformerのトークン数・計算量とVAE decode量が増える。encoderの重み自体を大きくする操作ではない。
VAE decodeは空間256px・時間32のタイル分割を継続し、latentから画素へ戻す段階のVRAMを抑える。タイルのoverlapは空間64・時間8。
1344×768でメモリ不足が起きた場合はログのencoder / sampling / VAE段階を確認し、offloadやtile設定を先に調整する。

計測ファイル: `latest_phase3_quality.json`, `measurements/phase3/`。Phase 1/2の計測結果は保存したまま別ファイルを使用する。
生成物の保存先は `ComfyUI/output/phase3/`。

### Phase 3 実測結果（成功）

1344×768・124フレーム・24fps・20 stepsをそのまま完走。sampling/VAE双方でOOMなし。
解像度・フレーム数・量子化・offload設定・VAE tile設定を下げる再試行は不要だった。

| 項目 | 実測 |
|---|---:|
| 生成時間（ComfyUI実行開始〜成功） | 895.131秒 / 14分55秒 |
| API全体時間 | 895.844秒 |
| sampling（ログ、概数） | 854秒 / 14分14秒、約42.7秒/step |
| peak GPU全体 | 11437MiB / 11.17GiB |
| peak server process-tree RSS | 7.31GiB |
| peak server private commit | 15.73GiB |
| peak PC物理RAM使用量 | 25.27GiB |
| peak PCコミット量 | 32.71GiB |
| 最小空き物理RAM | 36.38GiB |
| 安定性 | 1回の生成成功、OOMなし |

計測対象のprompt ID: `172a5fc0-7ee4-464b-a4c9-004f15479035`。
開始時GPU全体1639MiB、PC物理RAM15.75GiB。各ピークは異なる時点の場合がある。約1秒間隔のサンプリング値であり、瞬間ピークの保証はしない。
sampling中のGPU全体は主に約7.8GiB、RAMは約23〜25GiB。VRAM全量へモデルを常駐させずoffloadを利用して完走した。
768pでは画素数だけでなくattentionの計算量が増えるため、低解像度から生成時間が線形に増えるとは限らない。今回の約15分は標準PyTorch attention・このoffload設定での実測であり、最速設定の主張ではない。
Phase 2とは解像度・steps・sampler・Turbo適用が異なるので、この差をTurbo単独の速度倍率とは解釈しない。

生成物: `ComfyUI/output/phase3/H3_T2V_Quality_00001_.mp4`（3,209,950 bytes）。
H.264 1344×768、24fps、124フレーム、5.166667秒。AAC 32kHz stereo、5.166688秒。全動画フレームと音声をPyAVでデコード済み。
音声RMS 0.001400、peak 0.008109で非ゼロ。音声内容・聴感・同期の評価は未実施。
代表6フレームでは船体・帆・岸辺・水面反射を維持し、右への移動が見られる。原寸の中間フレームでは帆の継ぎ目や波紋が判別できる。
Prompt指定との一致は完全ではなく、船体の赤色は弱い。文字なし指定にもかかわらず帆に記号状の模様がある。
これは768pキャンバスでの成功と1場面の目視検証。pruned INT8 DiTを使用しており、未量子化BF16との品質一致、人物・複雑な動き・他Seedの品質は未検証。

検証成果物: `phase3_quality_inspection.json`, `phase3_validation.json`, `measurements/phase3/benchmarks.csv`。
`phase3_quality_contact_sheet.jpg` は代表6フレーム。`phase3_quality_first.png`, `phase3_quality_middle.png`, `phase3_quality_last.png` は原寸フレーム。
ComfyUIの画面で `02_H3_T2V_Quality`を開き、Prompt・設定ノートが表示されることを確認済み。

再計測はPhase 2のコマンドのworkflowを `02_H3_T2V_Quality.json`、resultsを `measurements/phase3`、latestを `latest_phase3_quality.json`、labelを `quality768` に変更する。
生成時間が長くてもsamplingログとGPU稼働が進んでいれば処理中。止まったと判断して同じキューを重ねない。

## Phase 4 First Frame I2V

`workflows/03_H3_I2V.json` を読み込む。専用ComfyUIの `H3_Learning`にも保存済み。
896×512（0.458752MP）・124フレーム・24fps・約5.17秒・Turbo 8 steps。Euler / simple、LoRA strength 1、video/audio shift 12/3。
First Frameのみを接続し、Last Frameは未接続。取得済みのモデルとTurbo LoRAを再利用し、追加ダウンロード・custom node・依存更新・Windows設定変更はない。

### 画像を差し替えて使う

1. ID18 `LoadImage` の画像アップロードボタンでSDXL/Z-Image等のPNG/JPEGを選ぶ。画像の生成元に依存する特別な変換は不要。専用の `ComfyUI/input/` にコピーして画像一覧から選んでもよい。
2. ID19の入力プレビューで画像を確認する。検証用初期画像は `input/h3_phase4_first_frame.png`（Phase 3の開始フレーム）で、SDXL/Z-Image生成画像ではない。
3. ID5でPrompt、width/height、lengthを変更。Promptには画像の説明だけでなく、動き・カメラ・音声を指定する。
4. ID6でSeed、ID8でStepsを変更。まず8 stepsを基準にする。4 stepsは高速試行用候補だが、このPhaseのI2Vでは未計測。
5. 実行すると `ComfyUI/output/phase4/` に動画が保存される。

入力画像と出力の縦横比を合わせる。現在の本体はFirst Frameをキャンバスへ直接stretchするため、例えば正方形画像を896×512へ入れると横長に変形する。
縦長人物画像ならwidth/heightも縦長に設定し、各辺は32の倍数を使用する。今回は1344×768入力と896×512出力がともに7:4で、縦横比の変形はない。
自動cropを暗黙に入れず、画像の構図と出力キャンバスの関係を学べる構成にしている。透明PNGを使う場合は先に背景を合成したRGB画像にする。ID18のMASK出力はこのworkflowでは使用しない。
フレーム数は17k+5に調整される。124フレームが約5.17秒。複数画像をbatchで渡してもこのノードのFirst Frameには最初の1枚だけが使われる。
SDXL/Z-Imageの生成処理自体はこのworkflowに含めない。画像を保存して渡す方式なので、既存Desktopのモデルやvenvを共有・更新する必要はない。

### 新しいデータ経路とノード

| ID / ノード | 入力 → 出力 | なぜ必要か |
|---|---|---|
| 18 LoadImage | PNG/JPEG → IMAGE、MASK | First Frameの画素を読み込む。IMAGE出力をID5へ渡す。MASKは未使用 |
| 19 PreviewImage | ID18 IMAGE → 画面プレビュー | 入力した画像を生成前に確認。samplingの条件自体を変更しない |
| 5 MiniMaxH3ImageToVideo | Prompt + First Frame + encoder + video VAE + サイズ/フレーム数 → conditioning + 空AV latent | 画像を2つの経路で条件に変換。Qwen3-VLが意味を読み、video VAEが画像をencodeしてframe index 0のkeyframe latentとしてconditioningへ格納 |

ID1〜14のその他のノードはPhase 1の表、ID16/17はPhase 2の表を参照。

```text
Prompt ───────────────────────┐
LoadImage → First Frame ───────┴→ Qwen3-VL → semantic conditioning ───┐
              └→ Video VAE encode → keyframe latent at frame 0 ─────┤
Resolution/frames → empty AV latent                                │
Seed → noise; Steps → sigmas                                       ├→ H3 sampling
INT8 H3 → Turbo LoRA → SigmaShift → Guider                          │     ↓
                                                                   ┘  generated AV latent
                                                                      ├→ Video VAE decode → frames
                                                                      └→ Audio VAE decode → audio
                                                                          → MP4
```

入力画像のlatentは、空のAV latent全体を置き換えるのではなく、開始時点のkeyframe条件としてH3へ渡る。
画像のピクセルをそのままMP4のframe 0へ貼り付ける経路ではない。VAE再構成・resize・動画圧縮で開始フレームにも差が生じる。
First Frameは開始の構図を指定する機能。長時間のidentity保持や他場面へのreference conditioningと同じ機能ではない。

### Phase 4 実測結果

| 項目 | 実測 |
|---|---:|
| 生成時間 | 130.002秒 / 2分10秒 |
| API全体時間 | 130.922秒 |
| peak GPU全体 | 11294MiB / 11.03GiB |
| peak server process-tree RSS | 6.48GiB |
| peak server private commit | 15.75GiB |
| peak PC物理RAM使用量 | 27.90GiB |
| peak PCコミット量 | 35.39GiB |
| 最小空き物理RAM | 33.75GiB |
| 安定性 | 1回成功・OOMなし |

prompt ID `4d3392db-cb63-4d2d-b646-78ecfd645013`、Seed 50709700。開始時GPU全体2320MiB、PC物理RAM17.25GiB。
生成前に専用モデルをunload。計測方法・約1秒サンプリングの限界は前述と同じ。
生成物 `ComfyUI/output/phase4/H3_I2V_00001_.mp4`、1,375,836 bytes。
H.264 896×512、124フレーム、24fps、5.166667秒。AAC 32kHz stereo 5.166688秒。全フレーム・音声をデコード済み。
音声は非ゼロ（RMS 0.03895 / peak 0.30063）。内容・聴感・同期は未評価。
代表フレームでは入力のヨット・岸辺・朝日の構図を維持し、船の右移動と水面反射の変化が見られる。
開始フレームと入力画像を896×512へLanczos縮小した画像の診断値は、8bit RGBのMAE約4.30、PSNR約31.55dB。
異なるresize実装、VAE再構成、H.264圧縮の影響も含む値であり、identityや動画品質の合否指標にはしない。
SDXL/Z-Imageの実画像、人物、他Seed、768p I2Vは未検証。今回の896×512 Turbo検証とPhase 3の768p T2Vを区別する。
768pの品質経路を試す場合は、Phase 3の標準グラフへ同じLoadImage→first_frame接続を追加する。今回の544p系Turboを768pでそのまま品質基準に使わない。

検証成果物: `phase4_validation.json`, `phase4_i2v_inspection.json`, `measurements/phase4/benchmarks.csv`。
入力画像のoriginとSHA256もvalidationに保存。`phase4_i2v_contact_sheet.jpg`は代表6フレーム、`phase4_i2v_first.png`, `phase4_i2v_middle.png`, `phase4_i2v_last.png`は生成動画から抽出した原寸画像。
UIでも `03_H3_I2V`を開き、Prompt・ノートを確認済み。`build_i2v_workflow.py`で再構築できる。
再計測は前述コマンドのworkflowを `03_H3_I2V.json`、resultsを `measurements/phase4`、latestを `latest_phase4_i2v.json`、labelを `i2v` に変更する。

## Phase 5 First / Last比較ワークフロー

同じPrompt・Seed・896×512・124フレーム・24fps・Turbo 8 stepsで3通りを比較する。
入力はPhase 3で生成した同じ動画の開始画像と終了画像。整合した画像ペアで接続と補間を学ぶための実験。
Firstは `input/h3_phase5_first_frame.png`、Lastは `input/h3_phase5_last_frame.png`。元のPhase 3画像は保存したまま専用inputへコピーしている。

| UI workflow | ID5へ接続する画像 | 意味 |
|---|---|---|
| `04_H3_FirstLast.json` | First + Last | 開始と終了の両端を指定し、その間を生成 |
| `04_H3_FirstLast_FirstOnly.json` | Firstのみ | 開始を指定、終了の構図はモデルに委ねる |
| `04_H3_FirstLast_LastOnly.json` | Lastのみ | 終了を指定、開始の構図はモデルに委ねる |

保存先は `workflows/` と専用UIの `H3_Learning`。同名 `_api.json` は計測用。
First画像はID18、Last画像はID20、Prompt・解像度・フレーム数はID5、SeedはID6、StepsはID8。
プレビューはID19 / ID21。各workflowで両画像を表示するが、未接続側の画像はH3の条件に含まれない。PreviewImageにつながっていることと、conditioningに使われることを区別する。
手動で接続を切り替える場合はID18 IMAGE→ID5 first_frame、ID20 IMAGE→ID5 last_frameのリンクを追加・削除する。LoadImageノード自体の削除は不要。
LastのLoadImageをbypassする操作では、任意入力の切断と同じ意味にならない場合があるので、条件入力のリンクで切り替える。

### ノードとデータフロー

| ノード | 入力 → 出力 | 必要な理由 |
|---|---|---|
| ID18 LoadImage / ID19 PreviewImage | First画像 → IMAGE / プレビュー | 開始画像を選択して確認 |
| ID20 LoadImage / ID21 PreviewImage | Last画像 → IMAGE / プレビュー | 終了画像を選択して確認 |
| ID5 MiniMaxH3ImageToVideo | Prompt、接続した画像、encoder、video VAE → conditioning + 空AV latent | 画像の意味とVAE latentを条件へ追加。Firstはframe 0、Lastは実フレーム数−1（今回は123）へ配置 |

接続した画像はFirst→Lastの順にQwen3-VLへ入り、video VAEでencodeされ、`minimax_keyframes`としてconditioningへ格納される。
`Prompt + keyframes → conditioning → H3 Transformer → video/audio latent → 各VAE decode → MP4`。
開始・終了の静止画を単にクロスフェードする処理ではない。間の動画と音声もH3が生成する。
ID1〜14のその他の役割はPhase 1、TurboとshiftのID16/17はPhase 2の表を参照。
今回のFL2VA重みのまま両端指定が可能であり、Ref2VA重みは不要。追加モデル・custom node・依存更新・システム設定変更は行わない。

現在の本体実装はFirstをstretch、Lastをaspect-preserving center cover-cropでキャンバスへ合わせる。
今回の両画像と出力は7:4なので違いは生じないが、異なる縦横比の画像ではFirstが変形し、Lastは端が切れる可能性がある。
両画像は同じ縦横比・同じキャラクター・近い背景から始めると差を解釈しやすい。大きく異なる姿勢やカメラを無理に指定すると、途中の変形や急な遷移が起こり得る。
First/Lastは画素の完全コピーではなくlatent条件。VAE・resize・H.264による差を含めて評価する。
Promptは「入力画像から開始」のようなFirst専用表現を避け、3構成で同じ中立の場面・動き・音声指定を使用した。

計測ファイル: `latest_phase5_first.json`, `latest_phase5_last.json`, `latest_phase5_both.json`, `measurements/phase5/`。
`build_firstlast_workflow.py`は3構成を再構築し、`run_phase5.py`はキューが空なら順にunload→生成・計測→全フレーム検証を行う。失敗した場合は次の試行へ進めない。

### Phase 5 実測結果（3構成とも成功）

各構成1回、Seed 50709700、同じ中立Promptと入力画像ペア。各試行前にモデルをunloadし、ノードキャッシュは無効。OSのファイルキャッシュは維持される。

| 項目 | Firstのみ | Lastのみ | First + Last |
|---|---:|---:|---:|
| 生成時間 | 130.052秒 | 129.239秒 | 140.086秒 |
| API全体時間 | 130.844秒 | 130.438秒 | 140.860秒 |
| peak GPU全体 | 11459MiB / 11.19GiB | 10767MiB / 10.51GiB | 11232MiB / 10.97GiB |
| peak server process-tree RSS | 6.50GiB | 6.45GiB | 6.51GiB |
| peak server private commit | 16.02GiB | 14.82GiB | 15.98GiB |
| peak PC物理RAM使用量 | 27.45GiB | 28.15GiB | 27.51GiB |
| peak PCコミット量 | 35.49GiB | 34.08GiB | 35.59GiB |
| 最小空き物理RAM | 34.20GiB | 33.50GiB | 34.13GiB |
| 安定性 | OOMなし・保存成功 | OOMなし・保存成功 | OOMなし・保存成功 |

両端指定は今回の片側指定より約10〜11秒長い。2画像のencode・conditioning等が増える構成だが、各処理の寄与やメモリ差の原因はこの1回ずつの測定だけで断定しない。
GPUはデスクトップ等も含む値、RAMはPC全体とサーバーを区別。約1秒サンプリングのピークであり、GPU allocatorの瞬間ピークではない。

入力を896×512へLanczos縮小した画像に対する、生成動画の端フレームの8bit RGB平均絶対誤差（MAE）:

| 端フレームの診断 | Firstのみ | Lastのみ | First + Last |
|---|---:|---:|---:|
| 生成開始 → First画像 | 4.32 | 12.12 | 4.18 |
| 生成終了 → Last画像 | 15.37 | 4.07 | 4.13 |

今回の整合した画像ペアでは、接続した側の端フレームが指定画像に近くなり、両端指定では双方が近くなった。数値は画像条件が使われたことの診断であり、identity・主観画質・滑らかさの総合点ではない。
代表フレームでは3構成とも船の形・岸辺・朝日の雰囲気を維持して右へ移動。Firstのみは終了位置が指定Lastより右へ進み、Lastのみは開始側の船位置・大きさ等が指定Firstと異なる。両端指定は指定された開始・終了の構図の間を生成した。
全フレームの隣接RGB MAEも `phase5_validation.json` に保存した。中央値はFirst 2.08 / Last 1.83 / Both 1.93、最大値は3.35 / 2.98 / 3.09。最終フレームへの遷移差は1.77 / 1.51 / 1.64で、今回の診断では終了だけ極端に跳ぶ傾向はなかった。カメラやidentityの品質保証には使わない。

3本ともH.264 896×512・124フレーム・24fps・5.166667秒、AAC 32kHz stereo・5.166688秒。全動画・音声をPyAVでデコード済み。
音声RMSはFirst 0.03383 / Last 0.03435 / Both 0.03713で非ゼロ。音声内容・聴感・同期は未評価。
出力は `ComfyUI/output/phase5/H3_FirstLast_first_00001_.mp4`, `H3_FirstLast_last_00001_.mp4`, `H3_FirstLast_both_00001_.mp4`。
今回の検証は同じ動画由来の整合した画像ペア・1 Seed・低解像度Turboの各1回。大きく異なる人物姿勢、別背景、768p、他Seedは未検証。

比較画像 `phase5_comparison.jpg` は上からFirst / Last / Both、左からframe 0 / 31 / 62 / 93 / 123。
各構成の6フレームは `phase5_first_contact_sheet.jpg`, `phase5_last_contact_sheet.jpg`, `phase5_both_contact_sheet.jpg`。原寸の開始・中間・終了PNGも各prefixで保存。
`phase5_validation.json` に画像のSHA256・origin・端点診断・隣接フレーム差、`measurements/phase5/benchmarks.csv` に実測一覧、各 `*_inspection.json` にストリーム情報を記録。
UIの一覧で3構成を確認し、主workflow `04_H3_FirstLast` のPrompt・設定ノートが表示されることも確認した。

## Phase 6 Reference / Ref2VA

### なぜ別モデルが必要か

FL2VAはFirst/Lastの時点を指定する重み。Ref2VAは画像・動画・音声を見た目、スタイル、動き、カメラ、声や音の参照として扱う別の重みである。
本体のノードも `MiniMaxH3ReferenceToVideo` を使用し、`minimax_refs`という参照latent群をconditioningへ格納する。First/Lastの `minimax_keyframes`と用途・条件形式が異なる。
Ref2VA重みをFL2VAとして読み替えたり、FL2VA用Turbo LoRAをRef2VAへ流用しない。
今回のRef2VA Turbo v0.1は開発元の推奨4 steps、Euler / simple、LoRA strength 1、video/audio shift 12/3。544p向け蒸留モデルを低解像度Draftとして検証する。
標準品質の20 stepsは別の基準で、4 stepsのまま未量子化・標準品質と同等だとは扱わない。

### 現在の公式対応と現実的な入力

公式ネイティブガイドは最大9画像、3動画、3単独音声、動画に対応する音声トラックを扱う。今回はその上限を一括投入せず、画像1枚＋短い素材から始める。
タグは接続順に `<Picture 1>`, `<Video 1>`, `<Audio 1>`。種類ごとに1から数える。Promptで各参照の役割を明示する。
画像はidentity/見た目・物体・背景・スタイル、動画は動き・カメラ等、音声は声や音の参照として公式に利用可能。ただし今回の実機試行はヨットと生成済み環境音であり、声の再現能力は未検証。

- 画像: `ref_image_size=match`で生成キャンバスの画素面積へ縮小（拡大しない）。`max`では短辺最大2048pxを保持するため、参照トークンと負荷が増える。現在の初期値はmatch。
- 動画: 24fps素材を使用。GetVideoComponentsはfpsも出力するが、H3のIMAGE batch入力自体にはfpsが付かないため、自動fps変換はしない。30fps素材をそのまま渡すと24fpsとして解釈される。事前に24fpsへ変換する。
- 動画の長さ: 公式の目安は2〜15秒。固定commitの実装では出力フレーム数まで切り詰め、17k+5へ切り下げ、少なくとも5フレームを要求する。この最小値を推奨長として使わない。今回の素材は56フレーム / 2.333秒。
- 動画の解像度: 今回は448×256。本体は参照動画を768p級上限へ合わせ、低解像度は拡大しない。ただしLoadVideoは先に素材をデコードするため、最初は短く縮小したファイルで試す。
- 音声: 今回は32kHz stereo WAV / 2.333秒。audio VAE入力は必要に応じてサンプルレートを32kHzへ変換する。長い音声もlatent量が増えるので、まず短い参照を使う。

動画と音声は参照条件であり、出力へのファイルコピーや合成ではない。開始フレームを同じ画像にしたい場合のFirst Frame固定とは目的が異なる。

### 保存したワークフローと操作

| UI workflow | 参照条件 | 入力箇所 |
|---|---|---|
| `05_H3_Reference.json` | 画像1枚 | ID18 Picture 1 |
| `05_H3_Reference_Audio.json` | 画像＋単独音声 | ID18 Picture 1、ID22 Audio 1 |
| `05_H3_Reference_Multimodal.json` | 画像＋動画＋単独音声 | ID18 Picture 1、ID20 Video 1、ID22 Audio 1 |

保存先は `workflows/` と専用UIの `H3_Learning`、同名 `_api.json` はAPI計測用。
共通896×512・124フレーム・24fps・約5.17秒・4 steps・Seed 50709700。Prompt / サイズ / フレーム数 / ref_image_sizeはID5、SeedはID6、StepsはID8。
画像・動画・音声は各Loadノードのアップロードボタンまたは一覧で差し替える。タグとPromptの役割指定も素材に合わせて編集する。
動画の付属音声を使う場合はID21のaudio出力をID5の同じ番号のref_video_audio入力へ接続する。その音声は単独音声とは別の扱いで、動画より先にAudioタグが割り当てられるためタグ順を確認する。今回の参照MP4は映像のみで、付属音声ペアは未検証。
参照数を増やすと追加端子が現れる。最初の画像はPicture 1、2枚目はPicture 2。参照間でidentity・動き・音を分担させる。追加画像・動画を単に接続するだけで意図通りの役割になるとは仮定しない。

### ノードが扱うデータ

| ID / ノード | 入力 → 出力 | なぜ必要か |
|---|---|---|
| 1 UNETLoader | Ref2VA INT8重み → MODEL | reference用Transformerを読み込む |
| 16 LoraLoaderModelOnly | Ref2VA MODEL + Ref2VA Turbo → MODEL | 4-step蒸留の差分重みを適用 |
| 18 LoadImage / 19 PreviewImage | 画像 → IMAGE / プレビュー | Picture 1の見た目を指定 |
| 20 LoadVideo | MP4 → VIDEO | 短い参照動画のコンテナを読み込む |
| 21 GetVideoComponents | VIDEO → IMAGE batch、AUDIO、fps等 | H3に渡す動画フレームを取り出す。今回audio出力は未接続 |
| 22 LoadAudio | WAV等 → AUDIO | 単独の参照音声波形を読み込む |
| 5 MiniMaxH3ReferenceToVideo | Prompt + refs + encoder + 各VAE → conditioning + 空AV latent | 参照の意味・latent・種類をまとめ、毎sampling stepでH3へ渡す |

```text
Prompt + reference tags ────────────────────┐
Picture / sampled video frames → Qwen3-VL ──┴→ text/multimodal hidden states ─┐
Picture / full reference video → Video VAE encode → reference latents ──────┤
Reference audio → Audio VAE encode → reference audio latent ────────────────┤
                                                                          └→ conditioning (minimax_refs)
Seed / Steps / empty target AV latent → Ref2VA Transformer sampling ───────────→ generated AV latent
                                                                              ├→ Video VAE decode → frames
                                                                              └→ Audio VAE decode → waveform → MP4
```

Qwen3-VLには動画から2fpsでサンプリングした画像と時刻が渡る。一方video VAEは参照動画フレームをencodeする。単独音声の波形はaudio VAEのlatent経路で渡り、encoderには音声参照のタグが加わる。Qwen3-VLがそのまま音声波形を聞く構成だとは説明しない。
参照latentは生成対象の空AV latentと別であり、ノイズ除去せず各stepで条件として再投入する。そのため参照動画・画像が大きいとsampling自体も遅くなる。
本workflowではvideo VAEとaudio VAEをID5へ接続済み。VAEを外すとその参照のlatent経路が欠けるため、単なるメモリ節約として無断で外さない。
ノードID6〜14の生成・decode・保存経路はPhase 1、SigmaShiftのID17はPhase 2と同じ役割。

### 参照素材と取得記録

素材は `ComfyUI/input/h3_phase6_reference_image.png`, `h3_phase6_reference_video.mp4`, `h3_phase6_reference_audio.wav`。
画像はPhase 3の開始フレーム、映像と音声はPhase 4の生成結果由来。録音した実人物やSDXL/Z-Image画像ではない。
`prepare_phase6_media.py`で短い24fps MP4（音声なし）と単独WAVを作成し、`phase6_reference_media.json`に由来・サイズ・フレーム数を記録する。
Ref2VA本体・LoRAは `download_phase6.py`で範囲指定取得し、完成時にbyte数とSHA256を照合。速度不足で6並列から12並列へ変更し、完了済み範囲を保持して再開した。
モデル・専用workflow以外の環境更新は行わない。既存FL2VA workflowも保存したまま。
`build_reference_workflow.py`で3構成を再構築。`run_phase6.py`はモデル検証記録を確認し、キューが空ならunload→各生成・計測→全フレーム検証を順に実行する。
計測は `latest_phase6_image.json`, `latest_phase6_audio.json`, `latest_phase6_multimodal.json`, `measurements/phase6/`。
Referenceノードの動的入力端子に対応するためworkflow生成helperを拡張し、計測器もReferenceノードのサイズ設定を記録できるよう変更した。既存workflow JSONは書き換えていない。

### Phase 6 実測結果（3構成成功）

出力は各896×512・124フレーム・24fps・約5.17秒。Ref2VA Turbo 4 steps、Seed 50709700、image size match。
各構成1試行。画像は共通だが、音声・動画の役割指定を加えるためPromptも一部変わる。この比較は各構成の動作と負荷の基準であり、参照だけを変えた厳密な効果検証ではない。

| 項目 | 画像のみ | 画像＋音声 | 画像＋動画＋音声 |
|---|---:|---:|---:|
| 生成時間 | 78.690秒 | 79.446秒 | 94.741秒 |
| API全体時間 | 79.235秒 | 80.703秒 | 95.485秒 |
| peak GPU全体 | 11319MiB / 11.05GiB | 10894MiB / 10.64GiB | 11156MiB / 10.89GiB |
| peak server process-tree RSS | 6.51GiB | 6.54GiB | 6.66GiB |
| peak server private commit | 15.78GiB | 15.28GiB | 15.92GiB |
| peak PC物理RAM使用量 | 25.08GiB | 28.23GiB | 27.97GiB |
| peak PCコミット量 | 35.53GiB | 35.11GiB | 35.70GiB |
| 最小空き物理RAM | 36.57GiB | 33.42GiB | 33.68GiB |
| 安定性 | OOMなし・保存成功 | OOMなし・保存成功 | OOMなし・保存成功 |

各試行前に専用モデルをunload、ノードキャッシュ無効、OSファイルキャッシュは維持。メモリ指標と約1秒サンプリングの限界は前述と同じ。RAM/VRAMの小さな差を参照方式の優劣とは断定しない。
Ref2VA本体には208 Turbo LoRA patchesが適用され、画像・動画・音声のVAE encodeとsampling/decode経路を含めて完走した。
3本ともH.264 896×512・24fps・124フレーム・5.166667秒、AAC 32kHz stereo・5.166688秒。全動画フレームと音声をPyAVでデコードした。

| 出力ファイル（ComfyUI/output/phase6） | byte数 | 音声RMS / peak |
|---|---:|---:|
| `H3_Reference_image_00001_.mp4` | 1,365,280 | 0.001033 / 0.004587 |
| `H3_Reference_audio_00001_.mp4` | 1,360,452 | 0.001159 / 0.006358 |
| `H3_Reference_multimodal_00001_.mp4` | 1,210,052 | 0.001280 / 0.015275 |

代表フレームでは白い帆・暗赤色の船体・岸辺・朝日の雰囲気と右への移動を維持する。帆の記号や形状の細部が完全に同一とは限らず、「少し近い構図」というPrompt指定は弱い。
画像Referenceでも入力に近い開始構図となったが、ノードの参照条件はframe 0への固定ではない。この1例の外見だけからFirst Frameと同じ機能だとは判断しない。
音声は非ゼロだが振幅が小さい。参照音声は出力へそのまま貼り付けられるものではなく、今回は音声内容・聴感・同期・voice保持を評価していない。
動画の動きがどれほど参照に一致するか、人物identityの保持、声の再現、複数参照の競合、768p、標準20 steps、ref_image_size max、最大参照数、動画付属音声のペアリングは未検証。

`phase6_comparison.jpg`は上から画像のみ／画像＋音声／画像＋動画＋音声、左からframe 0 / 31 / 62 / 93 / 123。
`phase6_validation.json`に3試行と入力素材のSHA256、`measurements/phase6/benchmarks.csv`に実測一覧、各 `phase6_*_inspection.json` にstream情報を保存。
各 `phase6_*_contact_sheet.jpg` に6代表フレーム、対応するfirst/middle/last PNGに原寸画像を保存。
まず `05_H3_Reference.json`から画像1枚を差し替えて練習し、次にAudio、Multimodal版へ進む。Promptに参照タグと役割を書き、入力が大きいときは先に短縮・縮小する。
参照ノードでOOMなら、video encode / encoder / samplingのどの段階かをログで確認し、参照解像度・長さ・数、image match設定、offloadを先に見直す。Ref2VAを極端な量子化へ切り替えることを最初の対処にしない。
モデル一覧でRef2VAやLoRAが見えなければ一覧を更新して専用workflowを再読込する。FL2VAの選択のままreference用ノードを実行しない。
API計測3試行とは別に、Multimodal版をGUIの実行ボタンから実行した。GUIが送信したモデル・LoRA・Prompt・sampling設定と画像/動画/音声の3つの参照リンクがAPI版に一致することを照合し、生成・保存・全動画/音声デコードが成功した。
動的入力を含むUI用JSONが実際に使えることの確認であり、追加のVRAM/RAMベンチマークには含めない。`phase6_gui_submission.json`, `phase6_gui_history.json`, `phase6_gui_validation.json`, `phase6_gui_inspection.json`に保存。

## 次のPhase

Phase 6は完了。2026-10-01の追加指示でPhase 7〜9を確認待ちなしで実行する。最新の追加記録は末尾のPhase 7以降を参照。
01〜07の目的別workflowは対応Phaseで動作確認したものを保存する。未実装workflowを名前だけ用意しない。
Reference用Ref2VAはFL2VAと別重みが必要。ControlNet Unionも現在の本体に適用ノードがあるので旧custom nodeを先に導入しない。

## 調査した一次情報

- MiniMax公式GitHub: https://github.com/MiniMax-AI/MiniMax-H3
- MiniMax公式HF: https://huggingface.co/MiniMaxAI/MiniMax-H3
- ComfyUI本体: https://github.com/Comfy-Org/ComfyUI
- H3公式ガイド: https://docs.comfy.org/tutorials/video/minimax/minimax-h3
- ネイティブworkflow: https://docs.comfy.org/tutorials/video/minimax/minimax-h3-native
- 配布元: https://huggingface.co/Comfy-Org/MiniMax-H3
- Blackwell対応: https://github.com/Comfy-Org/ComfyUI/discussions/6643
- GGUF変換元の説明: https://huggingface.co/unsloth/MiniMax-H3-GGUF
- Phase 2 Turbo開発元: https://github.com/ModelTC/Minimax-H3-Turbo
- 推奨steps / shiftとComfyUI用説明: https://github.com/ModelTC/Minimax-H3-Turbo/blob/main/COMFYUI_SETUP_AND_INFERENCE.md
- Turboモデル開発元HF: https://huggingface.co/lightx2v/Minimax-h3-Turbo

上記は調査したページであり、third-partyの性能値をこのPCの実測として扱わない。


## Phase 7: Pose / Depth / Canny ControlNet（2026-10-01 実測済み）

公式調査で旧ControlNet Unionから2.0への推奨変更を確認した。現在のComfyUI本体は5ブロックの旧版だけでなく10ブロックの2.0を自動判別する。実際のローダーとGPUログで2.0の読み込みを確認。非公式FunControl、controlnet_auxは追加していない。

追加モデル（すべて取得元リビジョン固定・SHA256検証済み）：

| 保存先（ComfyUI/models以下） | モデル | 容量 GB | 取得元 |
|---|---|---:|---|
| model_patches | minimax_h3_fun_controlnet_union_2.0_pruned_int8_convrot.safetensors | 4.531 | Comfy-Org/MiniMax-H3 |
| checkpoints | sdpose_wholebody_fp16.safetensors | 1.917 | Comfy-Org/SDPose |
| diffusion_models | rt_detr_v4-x-hgnet_fp16.safetensors | 0.124 | Comfy-Org/SDPose |
| geometry_estimation | depth_anything_3_base.safetensors | 0.542 | Comfy-Org/Depth-Anything-3 |

元モデルは [Alibaba PAI Union 2.0](https://huggingface.co/alibaba-pai/MiniMax-H3-Fun-Controlnet-Union-2.0)、ComfyUI手順は [公式ControlNetチュートリアル](https://docs.comfy.org/tutorials/video/minimax/minimax-h3-fun-controlnet)。従来のチュートリアルは旧Unionを掲載しているため、そのモデル指定だけを現在の2.0へ置換した。保存した `official_fun_controlnet.json` は調査用の公式テンプレートであり、作成した06系はサブグラフを展開した学習向け構成。

### ワークフローとデータフロー

- `06_H3_PoseControl.json`: 人物動画 → RTDETRの人物bbox → SDPoseの身体・手・顔・足のkeypoints → RGB骨格画像 → video VAE → 制御latent → ControlNet Union → H3 Transformer。別キャラクターの画像はLoadImage 18からRef2VAの画像referenceへ入り、外見を条件付ける。姿勢と外見は異なる入力経路で合流する。
- `06_H3_DepthControl.json`: 動画フレーム → DA3 Baseのmono depth → グレースケールdepth描画 → 同じUnion。DA3は504px長辺で推論し、元の画像サイズへ戻す。monoを使い、124枚を巨大なmultiviewとして一括推論しない。
- `06_H3_CannyControl.json`: 動画フレーム → Canny（閾値0.2 / 0.4）→ 同じUnion。服の輪郭や背景まで制御するので、キャラクターを変更する実験ではPoseと違う制約が生じる。
- `06_H3_Character_Source.json`: H3で今回の比較用キャラクター画像を作った動画。最初のフレームを `input/h3_phase7_character.png` に保存。赤髪、銀色ジャケット、紺色パンツ、白い靴。SDXL / Z-Imageで生成した画像へ置き換えられる。人物の実写身元を再現する評価ではない。

主要ノードの操作：18=外見画像、20=動作動画、5=Prompt / Resolution / Frame count、6=Seed、8=Steps、24=Control strengthと適用区間、28=制御画像、14=生成動画保存、31=制御マップ動画保存。Poseは25=SDPose checkpoint、26=人物検出モデル、27=人物bbox、29=keypoint抽出（低メモリ設定batch_size 2）。bbox経路では人物cropごとに処理するためbatch_sizeだけで大きく高速化するとは限らない。

`ControlNetApply`はMODELを入力し、制御ブランチを組み込んだMODELを出力する。conditioningそのものにPoseラベルを追加するノードではない。SchedulerとGuiderの両方へこのMODELを接続。音声位置へのcontrol skipはゼロにされるため、Poseが直接音声を指定するわけではない。Qwen reference側には `<Picture 1>` が入り、control_videoは `<Video 1>` とは異なる経路。

### 入力と実測

公式テンプレートの [人物動画](https://raw.githubusercontent.com/Comfy-Org/workflow_templates/main/input/dancer_field_pose.mp4) を取得（3,998,674 bytes）。元は1344x768 / 24fps / 124 frames。比較用に896x512へ縮小し、24fps / 124framesのまま `h3_phase7_dancer_24fps.mp4` に保存。今回フレーム水増し・端フレーム保持・速度変更はない。任意の動画を使う場合もfps、フレーム数、アスペクト比を合わせる。標準LoadVideoは自動で24fpsへ変換しない。短いcontrolは本体の仕様で最後のフレームを保持するので、動きを止めたくない場合は先に整える。

共通設定はRef2VA INT8 + Ref2VA Turbo 4step、896x512、124 frames、24fps、seed 50709700、control strength 1.0、画像reference=match。

| 制御 | 生成時間 秒 | GPU全体ピーク GiB | システムRAMピーク GiB |
|---|---:|---:|---:|
| Pose | 162.785 | 10.78 | 27.26 |
| Depth | 120.810 | 11.29 | 27.40 |
| Canny | 117.403 | 11.17 | 27.69 |

全3試行で成功し、生成動画と制御動画を124フレームまでデコード確認。生成動画には32kHz stereo AACも存在。記録は `latest_phase7_*.json`, `phase7_validation.json`, `measurements/phase7_summary.csv`。VRAM/RAMの測定定義は前述と同じで、ダウンロード時間は含まない。

### 結果と限界

`phase7_pose_comparison.jpg` は同一時刻の元動画・抽出骨格・別キャラクター生成を比較。腕振り、片足のステップ、回転の動きは伝わるが、完全な姿勢一致ではない。最初の姿勢は外見referenceの立ち姿に強く引かれた。遮蔽と速い動きでSDPoseの一部の関節が欠けるフレームがあり、そのフレームの忠実性も下がる。生成前に制御MP4を確認し、必要に応じて検出/描画閾値、入力品質、strength、stepsを調整する。4-step Turboの1 seedの結果から全人物への精度を保証しない。

代表フレームで赤髪・銀色上着・紺色パンツは保持。Depthも動きと大まかな人体形状を伝えた。Cannyでは元動画の草地や背景の輪郭が強く反映され、画像referenceとは背景が変わった。人物の動きを別キャラクターへ移す目的にはまずPoseを推奨。HEDもUnion 2.0の対応条件だが、今回HED抽出器は追加せず未実測。外部で用意したHED RGB動画ならLoadVideo → GetVideoComponentsのIMAGEを24のcontrol_videoへ直接接続できる。

## Phase 8〜9の実装と比較条件

- 長尺化: `07_H3_LongVideo.json`（2区間、約10.29秒）、`07_H3_LongVideo_30s.json`（6区間、約30.79秒）。各区間896x512 / 124frames / FL2VA Turbo 8step。最終画像を次のfirst_frameに接続し、結合時に重複する次区間の最初の1フレームと同じ長さの音声を除く。各区間の音声は独立生成なので、連結だけでは音の連続性を保証しない。
- GGUF比較モデル: `models/unet/minimax_h3_fl2va_pruned-Q4_K_M.gguf`、11,420,663,904 bytes、[leejet/MiniMax-H3-GGUF](https://huggingface.co/leejet/MiniMax-H3-GGUF)、revision `d9c4c6312b4728a68a15a35626d84775a6523783`。`phase9_gguf_models_verified.json` にSHA256記録。Q4を通常モデルに置換する目的ではなく、ユーザー指定の比較条件。
- GGUFローダー: [leejet/ComfyUI-GGUF](https://github.com/leejet/ComfyUI-GGUF)、commit `373048b8403a7820620065210a691263d4da0a61`、追加依存は専用venvのgguf 0.19.0のみ。PyTorchや他の既存パッケージは更新していない。通常の `start_h3.ps1` では無効、`start_h3_gguf.ps1` ではこの1フォルダーだけを許可。8190で既に動作中なら二重起動せず停止してから切り替える。
- 比較条件: 同じboat Prompt / seed / 124framesでbase 4/8/20steps、低解像度vs768p、Turbo 4/8steps、INT8vsGGUF、async offload有無、reserve-vram 2vs4、PyTorch SDPA vs split attention、標準EasyCache有無。`run_phase9.py` と `manage_h3_server.py` が専用サーバーだけをキュー空時に切り替え、実測を保存する。
- EasyCacheは近似高速化。H3音声劣化の [未解決報告](https://github.com/Comfy-Org/ComfyUI/issues/15326) があるため、速度だけで採用せず画像と音声の両方を比較する。コアファイルを書き換えるcache拡張は追加しない。
- 本体・ドライバー・pagefile・セキュリティ設定は変更していない。Phase 8〜9の実測結果は以下に記録した。


### Phase 9 Attention比較用の追加パッケージ

[Windows版SageAttentionの現在のリリース](https://github.com/woct0rdho/SageAttention/releases/tag/v2.2.0-windows.post6) のCUDA13 / torch2.10以上 / cp310-abi3 wheel（16,656,067 bytes）と、PyPIのtriton-windows 3.6.0.post26 / cp312 wheel（47,402,104 bytes）を専用venvへ追加。両wheelの公開SHA256と照合し、取得元と容量を `phase9_attention_packages.json` に保存。torch2.11では対応するTriton 3.6系を選び、最新の3.8へ機械的に更新しない。SageAttentionの [公式要件](https://github.com/thu-ml/SageAttention) と [Triton WindowsのBlackwell対応](https://github.com/woct0rdho/triton-windows) を確認した。

比較プロファイル `sage` は標準の `--use-sage-attention` を指定するため、この機能のためのcustom nodeは不要。通常起動は引き続きPyTorch SDPAを明示する。パッケージimportと実際のH3生成は成功。今回の低解像度Turbo4では54.335秒、PyTorch SDPAの70.898秒より約23%短縮。画質比較と測定の制約は以下を参照。SageAttention 3のWindows Blackwellにはmisaligned address報告とfork修正があるため、まず2.2系で比較する。GPUがBlackwellだから新しいkernelが必ず最速になるとは仮定しない。追加に際してPyTorch、Driver、CUDA Toolkit、システムPATHは変更していない。


## Phase 8: 長尺化の実測結果（2026-10-01）

| workflow | 区間数 | 出力フレーム / 秒 | 生成・結合時間 | GPU全体ピーク | システムRAMピーク |
|---|---:|---|---|---:|---:|
| 07_H3_LongVideo.json | 2 | 247 / 10.292秒 | 258.936秒 | 11.22GiB | 26.97GiB |
| 07_H3_LongVideo_30s.json | 6 | 739 / 30.792秒 | 773.938秒（12分54秒） | 11.22GiB | 30.43GiB |

全区間の生成と結合が成功。各区間は124フレーム / 24fps、出力の重複削除後の合計は `124 + (区間数 - 1) * 123`。10秒版と30秒版のH264全フレーム、32kHz stereo AACを最後までデコード確認。`phase8_validation.json` に区間・境界・時間・メモリ、`phase8_30s_timeline.jpg` に各区間の最初/中間/最後、`phase8_30s_seams.jpg` に5つの接続点の前後を保存した。

### 標準ノードでの接続と変更箇所

共有モデル1 / encoder2 / video VAE3 / audio VAE4 / sampler7 / Turbo LoRA16 / sigma shift17 / 最初の画像18。区間番号iの各ノードは100*iを足したIDに揃えてある（例:1区間目は105,106,...）。

- `*05 MiniMaxH3ImageToVideo`: Prompt、サイズ、フレーム数、前区間の最終画像を受け取り、conditioningと空AV latentを出力。
- `*06 RandomNoise`: 区間ごとのSeedからノイズを生成。`*08 BasicScheduler`は8 stepsのsigma列、`*09 BasicGuider`はMODELとconditioningをまとめる。
- `*10 SamplerCustomAdvanced`: 入力ノイズ・conditioning・schedule・MODELを使い、video/audio latentを生成。
- `*11 VAEDecodeTiled` / `*12 VAEDecodeAudio`: latentを画像バッチと音声へ変換。`*13 CreateVideo` / `*14 SaveVideo`で各区間のMP4も保存。
- `*20 ImageFromBatch`: 画像バッチのbatch_index=-1で最終画像を選び、次の`*05 first_frame`へ接続。
- 2区間目以降の`*21 ImageFromBatch`: 先頭の重複フレームを除く（index1、length123）。`*22 TrimAudioDuration`: 同じ1/24秒を音声から除く。
- `*23 ImageBatch` / `*24 AudioConcat`: 映像・音声の時間順結合。最後に共有13 / 14で結合動画を保存。

Prompt、Steps、Seedは各区間のノードで編集できる。全区間同じサイズを保つ。フレーム数を124から変更する場合は17k+5の規則と、`*21`のlength、`*22`のdurationも同じ設定に更新する。最終画像の抽出は-1なのでフレーム数変更に追従する。CPU/RAM offloadとタイルVAE decodeは前フェーズと同じ。巨大な動画を一度にH3へ入力する構成ではなく、生成区間を順につなぐ。

### Driftと接続境界の確認

- **Identity drift:** 代表フレームでは赤髪・銀色ジャケット・紺色パンツ・白い靴を30秒まで保った。顔や服の細部は少しずつ変化する。1キャラクター / 1チェーンの試験で、厳密な身元認識は行っていない。
- **Background drift:** 草地と丘の大枠は保持するが、草の細部、遠景の輪郭、空の明るさが徐々に変わる。毎回pixels→VAE latentへ戻すので完全な保存ではない。
- **Camera discontinuity:** 接続点の代表フレームに大きなカットや構図の跳びは見られなかった。画像MADは各境界で0.0058〜0.0095（0〜1スケール）で、通常の隣接フレーム差0.0010〜0.0067より大きい場合がある。動きの速度や向きまでは1枚の最終画像だけでは引き継がれず、区間の中で似た腕上げ動作を繰り返す傾向があった。固定カメラの保証や光学フローによる速度一致評価ではない。
- **Audio discontinuity:** 音声は区間ごとに新しく生成される。特に25.667秒の5番目の接続では、直前/直後0.25秒のRMSが0.00199→0.02568（約12.9倍）となり、音量の不連続が数値で確認できた。ほかの接続でもRMSが変化する。映像のアンカーが合っていても音声の連続性は独立に評価する必要がある。

各境界の1秒WAVを `phase8_30s_audio_seam_1.wav`〜`phase8_30s_audio_seam_5.wav` に書き出した。`phase8_10s_audio_seam_1.wav`もある。再生して音色・リズム・クリックの有無を確認できる。RMS / sample jumpは聴感や意味の一致を保証しない。音声品質を揃えたい用途では別の連続した環境音・BGMを全体に敷く、または音声latentを引き継ぐ方式を選ぶ。

[現在のMotion Context実装](https://github.com/NikoDemon80/ComfyUI-H3-Motion-Context) は前区間のvideo/audio latentのtailを固定して継続する方式。pixel roundtripと音声再生成を抑える設計で、ComfyUI 0.34以降のnative guide実装を利用する。今回の学習用基準は標準ノードのみのLast Frame→First Frameとして作成・実測し、この追加custom nodeは導入・実測していない。baselineの接続差と音声の問題が見える記録を保存したので、より高度な継続方式を後で同じ条件で比較できる。


## Phase 9: RTX 5070での比較結果（2026-10-01）

低解像度は896x512（0.459MP）、768pは1344x768。全条件124フレーム / 24fps / 約5.167秒、同じPrompt・Seed 50709700、Euler / simple。TEはNVFP4 AWQ、VAEsも共通。baseはTurboなし、turboはFL2VA 8step LoRAとsigma shift 12/3。条件ごとにモデルをunloadするがOSファイルキャッシュは維持。時間はサーバーの実行開始からencode、denoise、AV decode、MP4保存まで。起動・インストール・ダウンロードは除外。各条件1回なので測定差を統計的な優劣とはしない。

| 条件 | 秒 | GPUピーク GiB | システムRAMピーク GiB | 結果 |
|---|---:|---:|---:|---|
| gguf_turbo4_low | 130.116 | 10.52 | 40.85 | 成功 |
| base4_low | 73.464 | 11.35 | 28.15 | 成功 |
| base8_low | 108.941 | 11.15 | 28.39 | 成功 |
| base20_low | 238.580 | 11.13 | 28.33 | 成功 |
| base20_768p | 896.543 | 11.15 | 28.62 | 成功 |
| turbo4_low | 70.898 | 11.14 | 28.50 | 成功 |
| turbo8_low | 117.514 | 11.15 | 28.89 | 成功 |
| turbo4_768p | 215.570 | 11.14 | 28.91 | 成功 |
| turbo8_768p | 391.354 | 11.14 | 28.85 | 成功 |
| easycache20_low | 133.507 | 11.14 | 28.01 | 成功 |
| sync_turbo4_low | 69.879 | 11.36 | 28.99 | 成功 |
| reserve4_turbo4_low | 71.326 | 9.76 | 29.02 | 成功 |
| split_turbo4_low | 失敗まで5.485 | 10.60 | 24.27 | OOM |
| sage_turbo4_low | 54.335 | 11.22 | 29.00 | 成功 |
| gguf_base20_low | 411.824 | 11.22 | 40.40 | 成功 |

GPUはデスクトップ等を含むデバイス全体、RAMはシステム物理RAM使用量。ComfyUIのみのRSS・private commit・約1秒サンプルは各測定JSON/CSVに別記。成功14動画は124フレームと音声を最後までデコード確認。安定性は1 seed / 各1試行の結果であり長期安定保証ではない。

### 主観画質と制約

比較シートの5時刻を目視した。動画の全フレームは機械的にデコードしたが、リアルタイム視聴・音声の聴感評価は行っていない。構図が違うだけで画質順位を決めず、帆の文字らしい模様は正しい文字として評価しない。各条件の所見は `phase9_quality_notes.json`。

| 条件 | 代表フレームでの所見 |
|---|---|
| gguf_turbo4_low | 船体と白い帆・反射は一貫。INT8 Turbo4と帆の模様・色味に差がある。大きな崩れは見られない。 |
| base4_low | 遠い小さな船と空・反射は一貫。細部と動きは控えめ。 |
| base8_low | 4 stepsより船が大きく帆の模様が見える。構図と船体は代表フレームで安定。 |
| base20_low | 帆・船体・反射が明瞭。船はゆっくり右へ移動。細かな帆の文字は意味のある文字として評価しない。 |
| base20_768p | 船体、帆、波の細部と太陽の反射が見える。構図と動きは一貫するが、解像度変更で太陽や船の配置も変わる。 |
| turbo4_low | 大きめの船、帆の模様と水面反射が明瞭。代表フレームに大きな崩れはない。 |
| turbo8_low | Turbo4に近い構図で帆の模様と船体が安定。今回の画像では倍のstepsに比例する改善は確認できない。 |
| turbo4_768p | 船と波の細部が見える。太陽と雲、反射の位置はbase20とは異なる。大きな崩れは見られない。 |
| turbo8_768p | 船体と雲の輪郭は一貫。代表フレームだけではTurbo4より明確に良いとは判定できない。 |
| easycache20_low | base20と大枠は似るが船の位置、帆の模様、色味は変化。代表フレームに大きな崩れはない。音声の特徴量も変わり聴感未評価。 |
| sync_turbo4_low | 通常Turbo4と代表フレームの構図と細部がほぼ同じ。時間差は小さく単発では優劣を断定しない。 |
| reserve4_turbo4_low | 通常Turbo4と代表フレームの構図と細部がほぼ同じ。VRAMを抑えた。 |
| split_turbo4_low | 生成開始時のattention中間テンソルでOOM。出力動画なし、画質評価不可。 |
| sage_turbo4_low | 通常Turbo4と同じ船・構図・反射を保つ。微細な帆の模様は変わるが代表フレームに黒画像やノイズ崩壊はない。 |
| gguf_base20_low | INT8 base20に近い構図、船体と帆は安定。帆の模様と反射が変化。今回だけでは量子化の画質順位は決められない。 |

### 推奨設定

- **標準モデルはnative pruned INT8を継続。** Q4_K_Mはモデル保存容量を減らすが、今回Turbo4は130.116秒 / RAM40.85GiB、INT8は70.898秒 / RAM28.50GiB。base20も411.824秒対238.580秒。GGUF loaderの配置・LoRAの実装差を含む比較で、量子化だけの一般的性能差ではない。Q2への変更は不要。
- **試行錯誤は896x512 / Turbo4、品質確認は768p / Turbo8またはbase20。** Turbo4の768pは215.570秒、Turbo8は391.354秒、base20は896.543秒。今回の帆船では8stepへの増加が明確な画質向上とは言い切れず、人物や動きのあるPromptで確認して選ぶ。保存済み01/02の既定値を一括変更していない。
- **SageAttentionは高速化候補。** `start_h3_sage.ps1`を追加。実測54.335秒で約23%短縮、代表フレームで黒画像やノイズ崩壊なし。ただし低解像度Turbo4のみ検証済みで、768p・ControlNet・長尺での速度や安定性は未測定。通常の`start_h3.ps1`は再現性の基準としてPyTorch SDPAのまま。
- **VRAMに余裕を作る場合は`start_h3_reserve4.ps1`。** reserve-vram4の実測9.76GiB / 71.326秒、通常2は11.14GiB / 70.898秒。ほかのGPUアプリを併用するときの候補。RAM約29.02GiBで64GBを活用できた。async offloadなしの69.879秒は通常との差が小さく、単発で既定値を変更する根拠とはしない。
- **EasyCacheは実験用。** threshold0.2 / start0.15 / end0.95で10/20計算をskip、全体238.580→133.507秒（約44%短縮）。映像の大枠は保つが帆や位置・色味が変わり、音声RMSとスペクトルも変化した。既知の音声劣化報告を踏まえ、標準workflowへ自動適用せず比較用のみ。特徴量から音質の良し悪しは判定しない。
- **split attentionはこの設定では利用しない。** サンプラーの最初のattention中間演算で30.35GiBのGPU allocationを要求してOOM。モデル重みをRAMへoffloadしてもGPU上のattention行列はそのままRAMに逃がせない。極端な量子化に変更せず、生成に成功したSDPA/Sageを利用する。コアファイルは修正していない。

### 保存場所、起動と再実験

UI用JSONは `workflows/`、同名の`_api.json`はスクリプト用。ComfyUIの `user/default/workflows/H3_Learning/` にUIコピーを保存済み。主成果物01〜07に加え06_Depth/Canny、07_30s、15種類の09比較用workflowがある。GGUF用09だけは`start_h3_gguf.ps1`が必要。Sage/reserve4/sync等の09ファイル名だけでは起動設定は変更されないため、対応するlauncherまたは`manage_h3_server.py`のprofileを選ぶ。8190の専用サーバーが実行中ならキューを空にして停止してから切り替える。二重起動しない。

```powershell
cd C:\Users\uekus\Documents\comfyui-h3
.\start_h3.ps1
# オプション: .\start_h3_sage.ps1 または .\start_h3_reserve4.ps1
```

現在は標準のnative / PyTorch SDPAサーバーへ戻してある。取得済みモデル総量は85,887,374,493 bytes（85.887GB、79.989GiB）。Phase7追加7.113GB、Phase9 GGUF11.421GBとattention wheels合計64.058MB。保存場所と個別サイズは前述のモデル一覧とmanifestに記載。ドライバー・Windows・既存ComfyUIの変更なし。

GUI読込用JSONに`widgets_values_named`を追加し、現行frontendのモデル/メディア入力検証で名前と値が対応するようにした。Prompt → encoder → conditioning → H3 → AV latent → 各VAE → MP4の接続・生成パラメータは変えていない。古い開いたタブは閉じ、保存せず一覧から開き直す。追加モデルの警告が古い場合は問題パネルの「更新」でカタログを更新する。

比較結果は `measurements/phase9_summary.csv`, `phase9_validation.json`, `phase9_quality_notes.json`、画像は `phase9_steps_comparison.jpg`, `phase9_resolution_comparison.jpg`, `phase9_optimization_comparison.jpg`, `phase9_quant_cache_comparison.jpg`。AVファイルは `ComfyUI/output/phase7`, `phase8`, `phase9`。各検査JSONと測定サンプルも残してある。

### 追加パッケージの更新

`requirements-lock.txt`に今回のgguf / SageAttention / triton-windowsを含む最終バージョン、`requirements-lock-phase6.txt`に追加前の記録を保存。更新前は専用venvとworkflowsのバックアップ、公式ComfyUIとmodel作者の対応表・Windows wheelのtorch/CUDA/Python要件を確認し、別venvで短いAV生成を再測定する。通常起動でcustom nodesを無効にできるため、GGUFの更新がnative workflowへ波及しない。GGUFはモデル作者のforkの固定commitを使用し、更新時は変更差分を確認してpinを記録する。Driverや他環境のtorchを同時に更新しない。
