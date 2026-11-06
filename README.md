<img src="identity/cover.svg" width="1120" alt="听潮 Tingchao — Every forecast finds its place.">

**总部说 100，分店说 70 和 50。下一份计划，应该相信谁？**

听潮将总量与分项预测协调成满足加总关系的一组结果，保留原始判断、逐项调整与留出误差。它是一套 MoonBit 计算库，也是一张可以导入数据、切换方法和下载报告的预测工作台。

**[计算原理](handbook/mathematics.md) · [输入契约](handbook/exchange.md) · [库调用笔记](engine/README.mbt.md) · [场景与数据](cases/README.md)**

### 01 / 三条可复现的工作流

| 你在准备什么计划 | 听潮处理的矛盾 | 提供的结果 |
| --- | --- | --- |
| 连锁门店采购 | 总部与门店销量预测加不起来 | 固定历史误差权重下的协调值、调整量和节点误差 |
| 园区能耗安排 | 园区、分区、楼宇预测各自独立 | 两级加总约束下的预测与逐层偏差 |
| 景区服务资源 | 分区人数与全园总量不一致 | 自下而上汇总结果和留出评估 |

内置数据均为构造样例。另有一个反例专门展示“加总一致，但部分节点预测更差”。真实数据需要同单位、同周期与互不重复的叶节点。

### 02 / 打开工作台

需要 MoonBit **moonc `0.10.20+65efd5b93`** 和 Node.js **22.13 或更新版本**。本轮实测为 Node.js 24。使用 [MoonBit 官方安装器](https://www.moonbitlang.com/download/)的版本参数安装指定构建；先用 `moon version --all` 核对，而不是仅凭安装成功判断。

在仓库根目录执行：

```sh
moon run maintenance/build.mbtx --deny-warn
node studio/host.mjs
```

打开 **<http://127.0.0.1:8787>**。工作台支持样例选择、JSON 导入与编辑、周期切换、取消计算及输入/报告导出。计算在浏览器 Worker 中完成；输入不上传、不写入持久存储。停止服务使用 `Ctrl+C`。

### 03 / 在终端处理自己的文件

完成上面的构建后运行：

```sh
node _build/js/release/build/terminal/terminal.js cases/retail.json
node _build/js/release/build/terminal/terminal.js cases/energy.json --csv
```

JSON 或 CSV 写入标准输出，不修改输入文件。请求校验、文件错误和退出码见[输入契约](handbook/exchange.md)。也可将 `cases/` 中的文件作为自己数据的起点。

要在另一个 MoonBit 项目中使用，直接调用本模块的 `hierarchy`、`fit` / `fit_residuals`、`apply_many` 和 `evaluate`。完整示例见[随测试执行的库笔记](engine/README.mbt.md)。当前版本尚未发布到 Mooncakes，暂不提供一个尚不可用的安装命令。

### 04 / 选择你的协调方式

| 方式 | 使用的信息 | 适合先验证的情况 |
| --- | --- | --- |
| Bottom-up | 只保留叶节点预测，再向上加总 | 分支预测可信，上层只是汇总 |
| OLS | 所有节点等权参与最小二乘 | 暂无可靠历史误差资料 |
| WLS | 所有节点与固定对角误差方差 | 有独立校准期，或明确给定方差 |

OLS/WLS 使用带缩放的 Householder QR，不显式求逆。支持单根树，最多 128 个节点、64 个叶节点与 256 个预测周期。保留负预测值；不会通过截断破坏一致性。暂不实现交叉分组结构、非负约束、模型训练或 MinT 收缩协方差。

**一致性不等于准确率。** 有实际值时分别报告各节点 MAE/RMSE，完整保留变差的结果。校准期必须在预测期之前，外部模型是否存在训练泄漏仍需数据提供者确认。

### 05 / 从公式走到可检查的软件

```sh
moon check --target all --deny-warn
moon test --target wasm,wasm-gc,js --deny-warn
moon build --target js --release --deny-warn
moon fmt --check
moon run maintenance/verify.mbtx --deny-warn
```

测试包括独立闭式解、多层树的加权驻点条件、重复投影不变性、节点重排、极端方差与边界输入。文件验证另外检查三组场景及反例的父子加总、节点覆盖、调整量、CSV 与退出码。

本地验证覆盖 Wasm、Wasm GC、JavaScript；Windows Native 测试因未配置 MSVC C++ 工具和 SDK 而未完成。CI 配置会在 Linux 运行 Native 检查，但尚未推送，不能把配置存在当成远程验证通过。

```
engine/              纯计算库：树、投影、校准、评估
  exchange/          同一套 JSON 与 CSV 数据契约
  terminal/          有界文件输入的 Node.js 终端适配器
  browser/           提供给工作台的 MoonBit 导出
studio/              数据交互、Worker 与可视化
cases/               三类构造研究与一个准确率反例
handbook/            方法、决策、来源和验证记录
maintenance/         构建、复验与身份检查工具
```

由 **Lyllyl789** 维护，采用 [MIT](LICENSE)。算法与素材来源、AI 辅助范围见[来源说明](handbook/provenance.md)。
