# SourceFuse 项目申报书

[![CI](https://github.com/wulisususu/SourceFuse/actions/workflows/ci.yml/badge.svg)](https://github.com/wulisususu/SourceFuse/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/wulisususu/SourceFuse)](https://github.com/wulisususu/SourceFuse/releases)

## 基本信息

- **项目名称：** SourceFuse：MoonBit 多源数据确定性冲突仲裁基础库
- **参赛者：** wulisususu
- **联系方式：** 以赛事报名信息为准
- **GitHub 仓库链接：** https://github.com/wulisususu/SourceFuse
- **项目方向：** MoonBit 多源数据仲裁基础库 / 数据融合基础设施
- **是否为移植项目：** 否
- **当前版本：** v0.1.1
- **项目许可证：** Apache License 2.0
- **支持目标：** wasm / wasm-gc / js / native

## 项目简介

SourceFuse 是一个使用 MoonBit 实现的确定性多源数据冲突仲裁基础库，用于解决：

> 当多个来源同时为同一个字段提供不同候选值时，应该选择哪个值，以及为什么选择它？

在实际软件系统中，同一个字段可能同时来自人工录入、设备采集、规则计算、AI 模型识别或外部系统。例如 OCR 识别结果可能与人工修正结果不同，设备读取值可能与模型推断值冲突，不同业务系统也可能提供多个版本的数据。

简单使用“置信度最高”“最新值”或“多数投票”无法完整表达来源权威性、人工确认、字段锁定和精确冲突等业务语义。

SourceFuse 将这类问题抽象为独立的候选值模型、来源模型和确定性仲裁策略。调用方只需要提供候选值及其来源、权威度、置信度、版本和状态，SourceFuse 即可输出确定结果或显式冲突，同时保留完整来源证据和机器可读的决策轨迹。

项目核心代码不依赖 HTTP、数据库、文件系统、系统时间、AI 模型或具体业务框架，可作为独立 MoonBit 基础库嵌入数据采集、OCR、设备系统、AI 应用、表单系统、数据清洗和业务中台等不同场景。

即使完全移除 `cmd/` 和 `examples/`，`core/ + wire/ + tests` 仍然构成一个完整、可复用、可测试的基础库。

## 核心功能范围

- 提供统一的多源候选值模型 `Candidate`，支持 Human、Device、Rule、Model、External 等来源类型；
- 支持 Proposed、Confirmed、Locked 三种候选状态，表达普通候选、显式确认和不可静默覆盖的锁定值；
- 提供确定性仲裁入口 `reconcile(...)` 与 `reconcile_with_policy(...)`，相同输入和相同策略始终产生相同结果；
- 默认支持 Locked → Confirmed → Authority → Confidence → Revision 的确定性优先级；
- 支持自定义排序维度，可按业务需求组合 Authority、Confidence、Revision 等仲裁条件；
- 支持按 `SourceKind` 设置来源权威度，例如 Human > Device > Model，而无需修改仲裁引擎；
- 支持 Exact、ASCII Trim、ASCII Trim + Case Fold 等规范化模式；
- 对完全同优先级但值不同的候选返回显式 `EqualPriorityConflict`，不会使用数组顺序作为隐式最终规则；
- 对多个互相冲突的 Locked 候选返回 `LockedConflict`，避免锁定数据被静默覆盖；
- 支持多字段 `RecordInput` 仲裁，各字段独立计算，一个字段冲突不会丢失其他字段已经得到的结果；
- 支持重复字段名校验，避免记录结果出现不可唯一定位的字段；
- 为每次仲裁生成机器可读 `DecisionStep` 决策轨迹；
- 完整保留 `considered` 原始候选数据和 `supporters` 支持最终规范化结果的来源证据；
- `supporter_count` 仅用于表达结果获得多少来源支持，不参与多数投票或排序；
- 提供稳定的 `sourcefuse.record.v1` JSON 输入格式；
- 提供稳定的 `sourcefuse.decision-report.v1` 决策报告格式；
- 提供 JSON 解析、结构化错误、报告序列化和 `reconcile_record_json(...)` 一体化适配接口；
- 提供 native reference CLI，用于快速验证 JSON 输入，CLI 不包含独立仲裁逻辑；
- 提供 Human + OCR + Model、Device + Human + Model、多字段局部冲突等可运行示例；
- 提供核心模型、策略、记录级仲裁、来源追踪和 JSON Wire 层自动化测试；
- 持续通过 wasm、wasm-gc、js、native 多目标检查、测试和构建；
- 在 Ubuntu 与 Windows 环境执行 native CI；
- 使用 `moon info` 生成 MoonBit 公共接口，并在 CI 中校验关键 v0.1 API，防止公开接口意外漂移。

## 原创或参考说明

- **项目性质：** 原创基础库
- **项目仓库：** https://github.com/wulisususu/SourceFuse
- **是否基于其他项目移植：** 否
- **项目许可证：** Apache License 2.0

SourceFuse 并不是对某个 JavaScript、Rust、Java 或 Python 项目的直接移植，而是针对多源数据冲突问题进行独立抽象和 MoonBit 原生实现。

与相邻方案相比，本项目重点做了以下区分和重新设计：

- **不是多数投票。** Candidate 数量不是仲裁排序维度。多个低优先级来源不会仅凭数量覆盖 Locked、Confirmed 或更高权威来源；
- **不是概率式 Truth Discovery。** Confidence 是调用方提供的确定性排序信号，SourceFuse 不训练来源可靠度模型，也不估计真实值概率；
- **不是普通字段覆盖。** 最终值不会抹掉原始证据，结果保留所有 considered candidates、supporters 和决策轨迹；
- **不是 Workflow Engine。** SourceFuse 不负责任务调度、API 调用、数据库操作、模型调用、重试或工作流执行；
- **不是 Entity Resolution。** SourceFuse 假设候选已经属于同一个逻辑字段，不负责判断两个现实实体是否为同一对象；
- **不是 AI Agent Framework。** SourceFuse 不依赖大语言模型、Prompt 或工具调用流程，但可以作为 AI 系统中的确定性数据决策基础组件；
- **核心与适配层分离。** `core/` 保持纯确定性计算；JSON 能力放在 `wire/`；CLI 只作为 reference adapter；
- **显式冲突优先于随意选值。** 当不同值经过所有配置规则后仍完全同优先级时，返回 Conflict，而不是依赖输入顺序得到一个表面上的“答案”；
- **解释能力属于正式输出。** 来源证据和决策轨迹是正式数据模型的一部分，而不是日志或调试信息。

更完整的设计边界见 [docs/DIFFERENTIATION.md](docs/DIFFERENTIATION.md)。

## 快速开始

安装或更新 MoonBit 依赖后，可直接运行内置示例：

```bash
moon update
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

该示例包含三个来源：

```text
Human      "张珊"  confirmed
OCR        "张珊"  confidence=98
LLM        "张山"  confidence=91

          ↓ reconcile

winner: "张珊"
reason: confirmed evidence outranks ordinary proposals
supporters: Human + OCR
```

输出为版本化的 `sourcefuse.decision-report.v1` JSON，其中包含最终值、冲突状态、决策轨迹、全部 considered candidates 和 supporters。

更多示例：

```bash
moon run cmd/sourcefuse examples/device-human-model/record.json
moon run cmd/sourcefuse examples/conflicted-record/record.json
```

完整快速开始见 [docs/QUICKSTART.md](docs/QUICKSTART.md)。

## MoonBit API 示例

可直接使用 `core/`，不需要 JSON 或 CLI：

```moonbit
let candidates = [
  @sourcefuse.candidate(
    "张珊",
    "operator",
    @sourcefuse.Human,
    100,
    100,
    2,
    @sourcefuse.Confirmed,
  ),
  @sourcefuse.candidate(
    "张山",
    "model",
    @sourcefuse.Model,
    20,
    91,
    3,
    @sourcefuse.Proposed,
  ),
]

let result = @sourcefuse.reconcile(candidates)
```

默认仲裁顺序：

```text
Locked
  ↓
Confirmed
  ↓
Authority
  ↓
Confidence
  ↓
Revision
  ↓
不同值仍完全同优先级 → Explicit Conflict
```

JSON 一体化适配接口：

```moonbit
match @wire.reconcile_record_json(text, pretty=true) {
  Ok(report_json) => println(report_json)
  Err(error) => println(error.message)
}
```

## 技术架构

```text
typed candidates
      │
      v
   core/        纯确定性仲裁基础库
      │
      v
DecisionReport
      │
      v
   wire/        v1 JSON 输入 / 输出适配
      │
      └──────────────> cmd/sourcefuse
                        native reference CLI
```

| 路径 | 作用 |
| --- | --- |
| `core/` | Candidate、Policy、Conflict、记录仲裁与 DecisionReport |
| `wire/` | 稳定 v1 JSON 解析、错误模型与序列化 |
| `examples/` | 可运行的典型仲裁场景 |
| `cmd/sourcefuse/` | native reference adapter，不包含独立仲裁规则 |
| `docs/API.md` | v0.1 公共 API 契约 |
| `docs/POLICY.md` | 仲裁策略与优先级语义 |
| `docs/WIRE_SCHEMA.md` | JSON Wire Schema |
| `docs/DIFFERENTIATION.md` | 与相邻方案的设计差异 |
| `docs/EVALUATION.md` | 评审最短验证路径 |
| `CHANGELOG.md` | 版本与兼容性记录 |

## 测试与验证

当前 CI 持续验证：

```text
wasm       PASS
wasm-gc    PASS
js         PASS
native     PASS

Ubuntu native    PASS
Windows native   PASS
```

另外还会检查：

- 核心包不得依赖 JSON / wire adapter；
- 三个 reference CLI 示例必须得到预期结果；
- `moon package --list` 的发布文件集；
- `moon.mod`、README、CHANGELOG 的版本一致性；
- `moon info --target native` 生成的公共 `.mbti` 接口；
- v0.1 关键 core / wire 公共 API 不得意外消失。

## 文档

- [Quick Start](docs/QUICKSTART.md)
- [Public API Contract](docs/API.md)
- [Policy](docs/POLICY.md)
- [Records](docs/RECORDS.md)
- [Wire Schema](docs/WIRE_SCHEMA.md)
- [CLI](docs/CLI.md)
- [Design Differentiation](docs/DIFFERENTIATION.md)
- [Evaluation Path](docs/EVALUATION.md)
- [Release Process](docs/RELEASE.md)
- [Changelog](CHANGELOG.md)

## License

Apache-2.0
