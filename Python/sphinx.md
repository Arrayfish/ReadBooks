# [Sphinx](https://www.sphinx-doc.org/ja/master/)

Pythonのドキュメント生成ライブラリ  
ドキュメント生成ツールでは1強で他の代替手段はないっぽい。  

プラグインで機能を追加できる。

## 拡張プラグイン

サードパーティの拡張プラグインは別でインストールが必要

- myst_parser: markdownを有効化
- sphinx.ext.autodoc: docstringを読み込む
- sphinx.ext.napoleon: docstringをmarkdownで描けるようになる
- sphinxcontrib.mermaid: mermaidの有効化

### sphinx.ext.autodoc

この拡張を使うためには、conf.pyの最初でPyhtonコードのルートを指定するする必要がある。  
詳しくはconf.pyのサンプルを参照  
読み込む時にモジュールをロードするので、ファイル直で書かれているコードは実行されてしまう。  
autodoc2という改良版のサードパーティプラグインがあるらしい

### [myst](https://qiita.com/Tachy_Pochy/items/53866eea43d0ad93ea1d)

Sphinxで使用することができるmarkdownの方言  
reStructuredTextの代わりになる。  
ドキュメントや、自由な場所へのレファレンスなどが使える。  

## 設定ファイル

conf.pyを設定ファイルとして使用される  
htmlのテーマや、拡張プラグインなどをここに入れる

サンプル

```python
# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information
import pathlib
import sys
sys.path.insert(0, pathlib.Path(__file__).parents[2].resolve().as_posix())


project = 'Bqey-backend'
copyright = '2025, TR'
author = 'TR'
release = '6.0.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.duration",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "myst_parser",
    "sphinxcontrib.mermaid"
]

templates_path = ['_templates']
exclude_patterns = []

language = 'ja'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

```
