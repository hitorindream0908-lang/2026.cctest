# My Weather

天気と最高気温から「自分にとって最適な服装」を提案するアプリです。仕様は [SPEC.md](SPEC.md) が正本です。

## 進み具合（フェーズ1）

| 単位 | 内容 | 状態 |
| --- | --- | --- |
| 1-1 | 4タブの空画面、下部タブバー、テーマ | 完了 |
| 2-1〜2-4 | 場所と天気 | 未着手 |
| 3-1〜3-4 | 記録と提案（無料版） | 未着手 |
| 4-1〜4-2 | プレミアムと変換 | 未着手 |
| 5-1〜5-2 | 通知 | 未着手 |
| 6 | 受け入れ条件の確認 | 未着手 |

## Macで動かす（iPhoneシミュレータ）

### 最初の1回だけ

1. App Storeから **Xcode** をインストールし、一度起動して追加コンポーネントのインストールを済ませます。
2. ターミナルで次を実行します。
   ```bash
   xcode-select --install
   sudo xcodebuild -runFirstLaunch
   ```
3. **Flutter** をインストールします（Homebrewを使う場合）。
   ```bash
   brew install --cask flutter
   ```
   Homebrewがない場合は https://docs.flutter.dev/get-started/install/macos の手順に従います。
4. CocoaPodsをインストールします。
   ```bash
   brew install cocoapods
   ```
5. 確認します。`Xcode` と `Flutter` の行にチェックが付けばOKです（Android関連の警告は今は無視して構いません）。
   ```bash
   flutter doctor
   ```

### 毎回

```bash
cd 2026.cctest
git pull
cd my_weather
open -a Simulator
flutter run
```

シミュレータが複数あって選択を聞かれたら、iPhoneの番号を選びます。起動中にターミナルで `r` を押すとコードの変更を即反映、`q` で終了します。

### ダークモードの確認

シミュレータのメニューで **Features → Toggle Appearance**（または ⇧⌘A）を押すと、ライトとダークが切り替わります。
