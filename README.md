# Sombrero

## 開発用 Docker 環境のための手順（メモ）

一通りの手順：
1. 設定ファイルの作成
2. ストレージ・ディレクトリの作成
3. Docker イメージのビルド
4. アプリのセットアップ
5. サービスを起動

### 設定ファイル
設定例のファイルをコピー、必要に応じて編集。

```sh
$ cp config.yaml.example config.yaml
```

### ストレージ・ディレクトリ
設定に合わせて作成。

```sh
$ mkdir ./storage
```

### Dockerイメージのビルド

```sh
$ docker compose build
```

### アプリのセットアップ
コンテナ内で実行する。

```sh
$ docker compose run --rm sombrero bundle exec rake setup
```

### サービス（コンテナ）を起動

```sh
$ docker compose up -d
```
