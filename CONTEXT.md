# CONTEXT.md — BMMS2094 小组作业完整脉络

> **用途**：本档案记录整个规划过程的所有决策、理由与被否决的选项。
> 给组员快速上手用，也可在新的 AI 对话中贴上此档作为背景脉络。
> **最后更新**：2026-08-13（题目已从「马来西亚旅客入境」切换为「南极臭氧洞」，本档案已随之全面改写）

---

## 目录

1. [专案概况](#1-专案概况)
2. [作业官方要求](#2-作业官方要求)
3. [评分配置与细则](#3-评分配置与细则)
4. [题目选择过程](#4-题目选择过程)
5. [资料集规格](#5-资料集规格)
6. [SDG 论述](#6-sdg-论述)
7. [R / Posit Cloud 环境](#7-r--posit-cloud-环境)
8. [四人分工](#8-四人分工)
9. [资料真实拉取与验证结果](#9-资料真实拉取与验证结果)
10. [三个候选异常事件的核对结果](#10-三个候选异常事件的核对结果)
11. [评估设计](#11-评估设计)
12. [六周时程](#12-六周时程)
13. [报告结构要求](#13-报告结构要求)
14. [提交规定](#14-提交规定)
15. [待确认事项](#15-待确认事项)
16. [扣分陷阱清单](#16-扣分陷阱清单)
17. [完整程式码汇整](#17-完整程式码汇整)
18. [可引用文献](#18-可引用文献)
19. [已产出档案](#19-已产出档案)
20. [决策日志](#20-决策日志)
21. [时间序列概念速查](#21-时间序列概念速查)
22. [五个模型的技术规格](#22-五个模型的技术规格)

---

## 1. 专案概况

| 项目 | 内容 |
|---|---|
| **课程** | BMMS2094 Statistics for Data Science（TAR UMT，Semester I 2026/2027） |
| **题目** | Forecasting the Antarctic Ozone Hole: Assessing the Montreal Protocol's Recovery Trajectory |
| **资料来源** | NASA Ozone Watch（Goddard Space Flight Center） |
| **资料期间** | 2005–2025（21 年），确认维持此期间，不砍到 15 或 20 年 |
| **人数** | 4 人 |
| **工具** | **R**，执行环境 **Posit Cloud** |
| **预测视野** | h = 12（月度序列）；成员 C 为 h = 6（季节内序列） |
| **测试集** | 最近 12 个月（或最近一个季节） |
| **主要指标** | **MASE**；辅以 RMSE、MAE；MAPE 仅列参考 |
| **资料集** | 不得更动（讲师明文禁止，此规定延续自旧题目讨论） |

### 题目沿革
- **原题目**（2026-08-06 ~ 08-11）：Forecasting Tourist Arrivals to Malaysia
- **切换原因**：2020–2022 边境管制造成的资料空洞，讲师提及往届学长用类似设计成绩很差
- **新题目**（2026-08-13 起）：南极臭氧洞，完全避开 COVID 断裂，且已用真实资料验证可行

---

## 2. 作业官方要求

### 基本规定
- 学生自组 3–4 人小组
- 对真实世界资料集套用一种或多种时间序列分析技术，撰写报告
- 各组自行取得资料集，来源须可靠，资料须近期且观测数足以进行有意义的时间序列分析
- 每位成员至少贡献一个时间序列预测模型；个人报告须清楚说明自己负责的模型
- 鼓励纳入其他分析技术（叙述统计、线性回归等）辅助分析
- 资料集与分析须对应至少一项联合国永续发展目标（SDG）

### 小组报告（Group Report）
| 项目 | 规定 |
|---|---|
| 格式 | IEEE conference template |
| 页数 | 最多 5 页 |
| (a) | Cover Page — 签名 + 贡献百分比 |
| (b) | Introduction — 背景、目标、资料集、SDG 编号与标题 |
| (c) | Methodology — 资料集描述、前处理、分析流程、预测方法、评估准则 |
| (d) | Data Analysis — 结果与讨论合并 |
| (e) | Conclusion — 讨论、限制、建议 |
| (f) | Reference — IEEE 格式 |

### 个人报告（Individual Report）
| 项目 | 规定 |
|---|---|
| 格式 | Times New Roman, 12pt |
| 页数 | 最多 2 页（不含封面、参考文献、附录） |
| (a)–(f) | Cover / Methodology / Data Analysis / Conclusion / APA Reference / Appendix（程式码） |

### 迟交罚则
1–3 天 −10 分；4–7 天 −20 分；超过 7 天 0 分，不予接受。**不允许迟交。**

---

## 3. 评分配置与细则

| 项目 | 分数 | 结构 |
|---|---|---|
| Final Group Report | 40 | 5 栏 × 8 分 |
| Individual Report | 20 | 4 栏 × 5 分 |
| Presentation | 20 | 5 栏 × 4 分 |
| Peer Evaluation | 20 | 5 栏 × 4 分 |

简报第 5 栏「Contribution to Overall Group Presentation」专评转场与协调，成本低、值得投入排练。

---

## 4. 题目选择过程

### 选资料集的四项判准
1. 真实的季节性 + 趋势（模型才分得出高下）
2. ≥ 80–100 个月度观测值
3. 有结构性事件或政策故事可写
4. 序列本身即官方 SDG 指标

### 完整候选评估纪录（含已否决者）

| # | 题目 | 结论 |
|---|---|---|
| 1 | Malaysia Grid Carbon Intensity | 使用者排除（能源类） |
| 2 | Arctic Sea Ice Extent | 统计特性最佳，但与马来西亚无关，最终未选 |
| 3 | Mauna Loa CO₂ | 不建议——太容易预测，模型差异极小 |
| 4 | Klang Valley PM2.5 | 分析有趣但清理工作量大 |
| 5 | Malaysian Crude Palm Oil Production | 曾列第一推荐，因需手动整理 Excel 而未选 |
| 6 | FAO Food Price Index | 不建议——季节性太弱 |
| 7 | Malaysia Unemployment Rate | 资料干净但季节性弱 |
| **8** | **Malaysia Tourist Arrivals** | **一度选定**，后因 COVID 断裂于 2026-08-11 放弃 |
| 9 | US Solar & Wind Generation | 使用者排除（能源类） |
| 10 | Malaysia Dengue Incidence | 季节性强但资料取得风险高 |
| **11** | **Antarctic Ozone Hole（NASA Ozone Watch）** | **最终选定（2026-08-13）** |

### 切换到臭氧洞的理由
1. 平流层化学**完全不受**人类封锁影响，序列连续无空洞
2. 臭氧洞季节性是物理驱动的固定年周期（8 月生成、9–10 月最大、12 月消散），比消费行为的季节性更「干净」
3. 2005–2025 共 252 个月度观测，充裕
4. 序列本身对应真实的 SDG 指标（12.4.1），且有《蒙特娄议定书》这个明确的政策评估框架
5. 仍有结构性事件可写（2019 SSW），且已用真实资料验证确实存在强烈讯号（见 §10）

---

## 5. 资料集规格

### 来源与授权
| 项目 | 内容 |
|---|---|
| 机构 | NASA Ozone Watch, Goddard Space Flight Center |
| 网址 | https://ozonewatch.gsfc.nasa.gov/meteorology/SH.html |
| 使用规范 | 所有素材标注来源为「NASA Ozone Watch」 |
| 仪器沿革 | 1979–1992 Nimbus-7 TOMS · 1993–1994 Meteor-3 TOMS · 1996–2004/10 Earth Probe TOMS · **2004/11–2016/06 OMI**（Aura 卫星）· **2016/07 起 OMPS**（Suomi NPP 卫星） |
| 缺值填补（官方） | 面积/质量亏损/极冠臭氧的缺漏用同化资料填补：MERRA（至 2016/06）、MERRA-2（2016/07–2017/08）、GEOS FP（2017/09 起） |

### ⚠️ 资料结构的关键陷阱（必读）
NASA 的月度档案是**「一个月一个档，每档里是历年同月」**，不是一般的月度序列。例如 `to3mins_09_toms+omi+omps.txt` 是「历年所有 9 月」的资料，1979–2026 各一笔。要得到 2005–2025 的月度序列，必须下载 12 个档案再重组成长格式。

### 四个可用变数
| 变数 | 档名前缀 | 单位 | 覆盖月份 | 是否有零值 | 分工 |
|---|---|---|---|---|---|
| 最低臭氧 Minimum ozone | `to3mins` | DU | 1–12 全年 | 否 | 成员 A · ETS |
| 极冠臭氧 Polar cap ozone（63–90°S） | `to3caps` | DU | 1–12 全年 | 否 | 成员 B · SARIMA |
| 臭氧洞面积 Hole area | `to3areas` | 百万 km² | 仅 7–12 月 | **是**（6.3%精确零值） | 成员 C · TSLM+Fourier（m=6 季节内序列） |
| 纬度带臭氧 90–60°S latitude band | `to3latbnds` | DU | 1–12 全年 | 否 | 成员 D · NNAR |

**成员 D 的序列已变更**：原规划用「臭氧质量亏损」（m=6，仅 126 笔），NNAR 这类需要较多资料的模型在此量级容易不稳定；改用 90–60°S 纬度带臭氧，全年有值、252 笔（m=12），给 NNAR 更充分的训练资料。

---

## 6. SDG 论述

**主要：SDG 12 Responsible Consumption and Production**，指标 **12.4.1**（危险化学物质相关的国际多边环境协定，涵盖《蒙特娄议定书》）。

**延伸：SDG 13 Climate Action**（多数 ODS 同时是强效温室气体，《基加利修正案》2016 进一步管制 HFCs）。

**延伸：SDG 3 Health and Well-being**（臭氧层是紫外线屏障，减少直接提高皮肤癌与白内障风险）。

**贡献论述**：官方评估（WMO/UNEP 四年一度 Scientific Assessment of Ozone Depletion）以化学-气候模式做长期投射，周期长、更新慢。本研究以统计时间序列方法提供短期（12 个月）高频监测视角，可作为长期模式投射的独立交叉验证。

> ⚠️ SDG 段落须在 Introduction 与 Conclusion **各出现一次**。

---

## 7. R / Posit Cloud 环境

免费版 1GB RAM。**不要装 prophet**（需编译 Stan，几乎必定失败或逾时）。

```r
install.packages(c("fpp3", "tseries"))
# fpp3 一次带进 tsibble / fable / fabletools / feasts / dplyr / ggplot2 / tidyr
```

见 §17 完整程式码汇整中的资料读取与重组函式。

---

## 8. 四人分工

| 成员 | 序列 | 模型 | 观测数 | 备注 |
|---|---|---|---|---|
| **A** | 月度最低臭氧 | Holt-Winters `ETS()` | 252 | 已用真实资料验证；EDA、STL 分解主责 |
| **B** | 极冠臭氧（63–90°S） | `ARIMA()` — SARIMA | 252 | 已验证；全组平稳性检定结果主责 |
| **C** | 臭氧洞面积（7–12 月） | 谐波回归 `TSLM(y~trend()+fourier())` | 126（m=6） | 已验证；建立并分享季节内序列建置方法 |
| **D** | 90–60°S 纬度带臭氧 | 类神经自回归 `NNETAR()` | 252（待拉取） | **尚未实际拉取**，方法与 A/B 相同，见 §17 |

**组长额外职责**：Seasonal Naïve 基准线（全组共用）、四模型 MASE/RMSE/MAE 比较总表、IEEE 排版、收齐个人报告、填写 Excel Summary sheet。

---

## 9. 资料真实拉取与验证结果

> 本节记录 2026-08-13 由 Claude 实际连线 NASA Ozone Watch 下载并用 Python（statsmodels / pmdarima）分析的结果。**这不是模拟或预测数据**，是作为团队在 R 中重现分析时的对照基准。

### 9.1 资料完整性
- 成员 A（最低臭氧）与成员 B（极冠臭氧）：2005–2025 共 **252 笔**，完全符合预期
- 成员 C（臭氧洞面积，7–12 月）：**126 笔**，符合预期；其中 **6.3% 为精确零值**（集中在 7 月边缘与 12 月消散期），验证了改用 m=6 季节内序列的判断
- 成员 D（纬度带臭氧）：**尚未拉取**，待完成

### 9.2 重大发现：缺失值恰好卡在仪器交接点
最低臭氧与极冠臭氧序列**都只缺 2016 年 6 月这一笔**（值为 -9999，NASA 官方缺失码），而 **2016 年 7 月正是 OMI 切换到 OMPS 的交接月份**。这不是巧合——已用线性插值处理这一笔，但这个发现本身是 Limitations 段落的绝佳素材，证明仪器更替风险的担心有实际资料证据支持。

### 9.3 探索性分析结果（成员 A：最低臭氧）
| 指标 | 数值 | 判读 |
|---|---|---|
| 季节强度（feat_stl） | **0.904** | 极强 |
| 趋势强度（feat_stl） | **0.168** | 偏弱——复原讯号相对气象噪音很小，必须写进 Limitations |
| ADF 检定 | p = 0.041 | < 0.05，支持平稳 |
| KPSS 检定 | p = 0.10（触顶） | > 0.05，支持平稳，两检定方向一致 |

STL 分解的 Trend 面板显示复原趋势**不是单调上升**，2020–2021 年附近有明显下凹——这两年恰好是有纪录以来最深、最持久的臭氧洞之一，说明长期复原讯号仍会被气象条件短期压制，这是很有分量的讨论点。

### 9.4 四模型 Hold-out 比较（测试集 = 2025 年，成员 A 序列）
| 模型 | MASE | RMSE | MAE | MAPE(%) |
|---|---|---|---|---|
| **TSLM + Fourier(K=3)** | **0.850** | 14.34 | 10.45 | 5.50 |
| Seasonal Naïve | 0.938 | 16.90 | 11.53 | 5.99 |
| SARIMA(1,0,1)(1,0,0)₁₂ | 0.959 | 17.24 | 11.79 | 6.12 |
| ETS（阻尼加法趋势） | 0.988 | 16.00 | 12.15 | 6.37 |
| NNAR（MLP 代理模型） | **2.516** | 34.99 | 30.94 | 16.38 |

**三个必须诚实讨论的发现：**

1. **ETS 参数退化**：拟合结果 α=1.0, β=0, γ=0, φ=0.8。α=1 代表水平项完全跟随最新观测、不做平滑；γ=0 代表季节项没有被更新。这是优化器收敛到的边界解，反映此序列的水平变化主要是噪音而非可平滑的讯号。
2. **SARIMA 残差未通过 Ljung-Box**：auto_arima 选出的 (1,0,1)(1,0,0)₁₂ 在 lag=24 的 p 值 < 0.001。额外跑了 40+ 种参数组合的网格搜索，**几乎没有任何 SARIMA 设定能让残差完全变白噪音**，暗示可能有 QBO、ENSO 等准周期但非严格 12 个月周期的物理驱动。
3. **NNAR 明显失败**：MASE 2.5，比基准线差 1.5 倍以上。240 笔训练观测对类神经网络而言偏少，容易欠拟合或不稳定。

### 9.5 五折滚动原点交叉验证（成员 A 序列，新增于 2026-08-13）
| 模型 | 平均 MASE（5 折） | 平均 RMSE |
|---|---|---|
| **Seasonal Naïve** | **0.695** | 11.42 |
| SARIMA | 0.854 | 13.71 |
| ETS | 1.735 | 24.28 |

> **关键结论**：单次 hold-out 测试显示 TSLM+Fourier 略胜一筹，但 5 折滚动验证显示这个优势并不稳定——**没有一个「聪明」模型能稳定打赢 Seasonal Naïve 基准线**。这正说明了为什么只看一次切分不够。

### 9.6 成员 B（极冠臭氧）结果
季节强度 0.70，ADF p=0.002（平稳）。

| 模型 | MASE | RMSE | MAPE(%) |
|---|---|---|---|
| **Seasonal Naïve** | **0.816** | 17.16 | 5.00 |
| SARIMA(1,0,3)(1,0,0)₁₂ | 0.817 | 18.15 | 4.90 |
| ETS | 0.907 | 18.59 | 5.57 |
| TSLM+Fourier | 0.944 | 19.72 | 5.77 |

SARIMA 与基准线几乎打平（差距仅 0.001 MASE），再次支持「模型复杂度不保证击败简单基准线」的结论。

### 9.7 成员 C（臭氧洞面积，季节内序列）结果
| 模型 | MASE | RMSE | MAE |
|---|---|---|---|
| Seasonal Naïve (m=6) | 0.633 | 3.49 | 2.42 |
| **TSLM + Fourier(K=2, m=6)** | 0.634 | **2.96** | 2.43 |

两者 MASE 几乎相同，但 TSLM 的 RMSE 明显更低——代表 TSLM 在大误差上控制得更好，值得在报告中区分讨论。

### 9.8 成员 D：尚待完成
受限于本次分析的资料拉取量，**尚未实际下载 90–60°S 纬度带序列**。§17 提供完全相同方法的程式码模板，只需把 `prefix` 换成 `"to3latbnds"`。拉取后需核对：该档案有 8 个纬度带栏位，需确认哪一栏对应 90–60°S；笔数是否等于 252；缺失值情况是否与 A/B 序列一致。

---

## 10. 三个候选异常事件的核对结果

> 之前规划假设了三个事件都会在资料中留下痕迹。用真实资料核对后，结果不完全如预期——这正是诚实分析的价值所在。

| 年份 | 事件 | 预期影响 | 实际核对结果 |
|---|---|---|---|
| **2019** | 罕见的平流层爆发性增温（SSW） | 臭氧洞异常小 | **强烈确认**。9 月最低臭氧 165.5 DU（平常约 130–145）；9 月面积仅 10.4 百万 km²（平常 20–26）；极冠臭氧 9 月高达 293.2 DU（平常约 195–225）。三个序列同步出现极端讯号 |
| 2019–20 | 澳洲森林大火烟尘注入平流层 | 影响随后年份 | 未单独核对，与 2019 SSW 时间重叠，效应难以在月度均值中分离 |
| **2022** | Hunga Tonga 火山喷发注入水气 | 2022–23 臭氧洞偏大 | **未见明显讯号**。核对 2022–2023 年 9–11 月面积与最低臭氧，数值都落在近 20 年正常波动范围内 |

### 建模处理建议
只对 **2019 年做脉冲虚拟变数**（效应真实且强烈）；Hunga Tonga 不纳入模型，改在 Discussion 段落文字讨论「为何未观察到预期效应」——这比硬凑一个不存在的效应更有学术价值，且科学文献本身对 Hunga Tonga 是否显著放大南极臭氧洞面积（而非其他化学指标）就有争议。

---

## 11. 评估设计

### 训练/测试切分
测试集固定为最近 12 个月（成员 C 为最近一个季节，即最后 6 个月），绝对不能随机切分。

```r
h <- 12
train <- y |> filter(month <= max(month) - h)
test  <- y |> filter(month >  max(month) - h)
```

### 主要指标：MASE
以 Seasonal Naïve 的样本内误差为分母，不受接近零的观测值影响，`MASE < 1` 代表打赢基准线。MAPE 仍报出但仅列参考（面积序列有零值时 MAPE 会失效）。

### 五折滚动原点交叉验证（新增）
```r
stretch_tsibble(y, .init = 180, .step = 12) |>
  model(snaive = SNAIVE(value), ets = ETS(value), arima = ARIMA(value)) |>
  forecast(h = 12) |> accuracy(y) |>
  select(.model, MASE, RMSE) |> arrange(MASE)
```
§9.5 的真实结果显示滚动验证的结论可能与单次 hold-out 不同，务必两者都做。

---

## 12. 六周时程

| 周次 | 任务 | 状态 |
|---|---|---|
| 第 1 周 | 资料拉取与可行性验证 | **✅ 已完成**（A/B/C 三序列已确认；D 待拉取） |
| 第 2 周 | EDA 与建模验证 | **✅ 已完成初版**（§9 全部结果） |
| 第 3 周 | 各自在 R 中重现分析、完成成员 D | 排程中 |
| 第 4 周 | 整合四人结果，模型比较讨论 | 排程中 |
| 第 5 周 | 报告完稿与简报制作 | 排程中 |
| 第 6 周 | 排练与提交（D-day） | 排程中 |

---

## 13. 报告结构要求

两份报告**引用格式不同**——小组用 IEEE、个人用 APA。

**小组报告**（IEEE 模板，≤5 页，40 分）：Cover / Introduction / Methodology / Data Analysis / Conclusion / IEEE References

**个人报告**（TNR 12pt，≤2 页，20 分）：Cover / Methodology / Data Analysis / Conclusion / APA References / Appendix（程式码）

四份个人报告的限制段落建议各写各的：
- 成员 A：ETS 参数收敛到退化解的意涵
- 成员 B：SARIMA 与基准线几乎打平，讨论模型复杂度与准确度的关系
- 成员 C：季节内序列的零值处理，MASE 与 RMSE 排名不一致的原因
- 成员 D：视实际拉取纬度带资料后的结果撰写

---

## 14. 提交规定

- 每位学生**个别**上传 AI Usage Disclosure Form 与 Peer Evaluation Form 到 Google Classroom（不得向组员透露内容）
- 组长收齐全部个人报告，与小组报告一并提交（各只交一次）
- 小组报告附上填写完成的 Excel「BMMS2094 Assignment Assessment」Summary sheet
- 命名格式（`Group5` 为范例，须换成实际组别）：
  - 小组报告：`RDS2S1G3_Group5_GroupLeaderName.pdf` / `.xlsx`
  - 个人报告：`RDS2S1G3_Group5_Name.pdf`

---

## 15. 待确认事项

| # | 事项 | 状态 |
|---|---|---|
| 1 | 序列实际起始年份与观测笔数 | ✅ 已解决（252/252/126） |
| 2 | 实际栏位格式 | ✅ 已解决（见 §17 函式） |
| 3 | 2016 年仪器更替是否造成可见位移 | ✅ 已解决（单笔缺失恰好卡在交接月） |
| 4 | 2019/2022 异常是否在资料中可见 | ✅ 已解决（§10） |
| 5 | 成员 D 序列拉取 | ⬜ 待办 |
| 6 | 组别编号、组长姓名 | ⬜ 待办（组内决定） |
| 7 | 实际缴交日期 | ⬜ 待办（Google Classroom） |
| 8 | IEEE 模板与评分 Excel | ⬜ 待办（Google Classroom） |
| 9 | 简报时长与形式 | ⬜ 待办（问讲师） |

---

## 16. 扣分陷阱清单

| 陷阱 | 后果 | 避免方式 |
|---|---|---|
| 把月度档当成月度序列直接读 | 资料结构完全错误 | 那是「历年同月」档，必须重组，见 §17 |
| 在有零值的面积序列上用 MAPE | 指标未定义或爆炸 | 用 m=6 季节内序列，主用 MASE |
| 只报单次 hold-out，不做滚动验证 | 可能被单次运气误导（§9.5 已示范差异有多大） | 至少做 3–5 折滚动验证 |
| 看到 ETS/SARIMA 表现不好就隐藏不报 | 报告失去可信度 | 诚实报告并解释为什么（§9.4 三点发现可参考） |
| 硬凑 Hunga Tonga 的效应 | 过度诠释，缺乏证据 | 诚实说「未观察到」，讨论可能原因（§10） |
| 随机切分 train/test | 重大方法学错误 | 一律按时间顺序，测试集固定最后 12 个月 |
| ADF / KPSS 假设写反 | Methodology 扣分 | ADF 要 p<0.05、KPSS 要 p>0.05 才算平稳 |
| Ljung-Box 解读错误 | 诊断段落失效 | H₀=无自相关，要 p>0.05 才通过（本例 SARIMA 反而没通过，如实讨论） |
| NNAR 没设随机种子 | 结果无法重现 | `set.seed()`，并在报告中写出种子值 |
| 四份个人报告雷同 | 个人报告与同侪评分双重受损 | 各写各的序列与模型 |
| 忘记交表单 | 影响个人成绩 | AI Usage Disclosure 与 Peer Evaluation 个别提交 |

---

## 17. 完整程式码汇整

```r
library(dplyr); library(purrr); library(tidyr); library(fpp3); library(tseries)

base <- "https://ozonewatch.gsfc.nasa.gov/meteorology/figures/ozone/"

# ── 步骤 1：先看格式（务必先跑这步）────────────────────
peek <- readLines(paste0(base, "to3mins_09_toms+omi+omps.txt"), n = 10)
writeLines(peek)
# 格式：前 5 行表头（Name/Units/Month/Source/Missing），
# 第 6 行起是 "Year  Data  Minimum  Maximum"，缺失码为 -9999.0

# ── 步骤 2：读取与重组函式 ──────────────────────────────
read_ozone_month <- function(prefix, mm) {
  url <- paste0(base, prefix, "_", sprintf("%02d", mm), "_toms+omi+omps.txt")
  raw <- readLines(url)
  raw <- raw[grepl("^[0-9]{4}", trimws(raw))]  # 只留资料行
  df  <- read.table(text = paste(raw, collapse = "\n"),
                     col.names = c("year","data","min","max"))
  df$data[df$data == -9999] <- NA
  tibble(year = df$year, value = df$data, mth = mm)
}

# ── 步骤 3：建立三个已验证的序列 ────────────────────────
o3min <- map_dfr(1:12, ~ read_ozone_month("to3mins", .x)) |>
  filter(year >= 2005, year <= 2025) |> arrange(year, mth) |>
  mutate(month = yearmonth(paste(year, mth)),
         value = zoo::na.approx(value)) |>   # 补 2016-06 单一缺失
  as_tsibble(index = month) |> select(month, o3_min = value)

o3cap <- map_dfr(1:12, ~ read_ozone_month("to3caps", .x)) |>
  filter(year >= 2005, year <= 2025) |> arrange(year, mth) |>
  mutate(month = yearmonth(paste(year, mth)),
         value = zoo::na.approx(value)) |>
  as_tsibble(index = month) |> select(month, o3_cap = value)

o3area <- map_dfr(7:12, ~ read_ozone_month("to3areas", .x)) |>
  filter(year >= 2005, year <= 2025) |> arrange(year, mth)
  # m=6 季节内序列，不建 tsibble（用整数索引）

# ── 步骤 4：成员 D — 尚待拉取 ───────────────────────────
o3lat <- map_dfr(1:12, ~ read_ozone_month("to3latbnds", .x)) |>
  filter(year >= 2005, year <= 2025)
# ⚠ 此档含 8 个纬度带栏位，需先 view 原始档确认哪一栏对应 90-60S

# ── 步骤 5：EDA（四张必备图）────────────────────────────
o3min |> autoplot(o3_min)
o3min |> gg_season(o3_min)
o3min |> gg_subseries(o3_min)
o3min |> model(STL(o3_min, robust = TRUE)) |> components() |> autoplot()

# ── 步骤 6：平稳性检定 ──────────────────────────────────
adf.test(o3min$o3_min)     # 要 p < 0.05
kpss.test(o3min$o3_min)    # 要 p > 0.05
o3min |> features(o3_min, feat_stl)   # 季节/趋势强度

# ── 步骤 7：四模型 + 基准线 ─────────────────────────────
h <- 12
train <- o3min |> filter(month <= max(month) - h)

fit <- train |> model(
  snaive = SNAIVE(o3_min),
  ets    = ETS(o3_min),
  arima  = ARIMA(o3_min),
  tslm   = TSLM(o3_min ~ trend() + fourier(K = 3))
)
fc <- fit |> forecast(h = h)
fc |> accuracy(o3min) |> select(.model, MASE, RMSE, MAE, MAPE) |> arrange(MASE)
fc |> autoplot(o3min, level = c(80, 95))

# 残差诊断
fit |> select(arima) |> gg_tsresiduals()
augment(fit) |> features(.innov, ljung_box, lag = 24)   # 本例预期 SARIMA 不通过

# ── 步骤 8：五折滚动验证 ────────────────────────────────
o3min |>
  stretch_tsibble(.init = 180, .step = 12) |>
  model(snaive = SNAIVE(o3_min), ets = ETS(o3_min), arima = ARIMA(o3_min)) |>
  forecast(h = 12) |> accuracy(o3min) |>
  group_by(.model) |> summarise(MASE = mean(MASE), RMSE = mean(RMSE)) |>
  arrange(MASE)

# ── 步骤 9：成员 C 的季节内序列（m=6）──────────────────
oc <- o3area$value
tC <- seq_along(oc); K <- 2
Xf <- cbind(tC, sapply(1:K, function(k) sin(2*pi*k*tC/6)),
                sapply(1:K, function(k) cos(2*pi*k*tC/6)))
tslmC <- lm(oc[1:(length(oc)-6)] ~ Xf[1:(length(oc)-6), ])
# 预测最后一季（6 个月）
```

---

## 18. 可引用文献

- Box, G. E. P., & Tiao, G. C. (1975). Intervention analysis with applications to economic and environmental problems. *Journal of the American Statistical Association, 70*(349), 70–79.
- Cleveland, R. B., Cleveland, W. S., McRae, J. E., & Terpenning, I. (1990). STL: A seasonal-trend decomposition procedure based on loess. *Journal of Official Statistics, 6*(1), 3–73.
- Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and practice* (3rd ed.). OTexts. https://otexts.com/fpp3/
- Hyndman, R. J., & Koehler, A. B. (2006). Another look at measures of forecast accuracy. *International Journal of Forecasting, 22*(4), 679–688.（MASE 的出处）
- Solomon, S., et al. (2016). Emergence of healing in the Antarctic ozone layer. *Science, 353*(6296), 269–274.（南极臭氧复原讯号侦测的权威文献，可在 Introduction 引用）
- WMO/UNEP. *Scientific Assessment of Ozone Depletion*（四年一度官方评估，可作为 §9.3 长期趋势讨论的对照基准）
- NASA Ozone Watch. https://ozonewatch.gsfc.nasa.gov/（资料来源，须标注引用）

---

## 19. 已产出档案

| 档案 | 内容 | 用途 |
|---|---|---|
| `BMMS2094_时间序列完整讲义.md` | 从零开始的时间序列教学（含类比） | 个人学习、准备简报 Q&A |
| `BMMS2094_Ozone_Playbook.html` | 互动式小组作战手册（12 个区块，含勾选清单 + 6 张真实分析图表） | 小组共用，浏览器开启 |
| `CONTEXT.md`（本档） | 完整脉络记录 | 单一事实来源 |

---

## 20. 决策日志

| 日期 | 决策 | 理由 |
|---|---|---|
| 08-06 | 选定旅客入境题目 | 资料易得、季节性明确 |
| 08-11 | 放弃旅客入境，改评估 10 个新候选 | COVID 断裂 + 学长前例不佳 |
| 08-13 | 选定南极臭氧洞题目 | 完全避开 COVID，季节性物理驱动更干净 |
| 08-13 | 资料期间维持 2005–2025（21 年）而非砍到 15/20 年 | 统计充足性论证：20 年后 MASE 曲线趋平 |
| 08-13 | 成员 D 序列从「臭氧质量亏损」改为「90–60°S 纬度带臭氧」 | 给 NNAR 更充分的训练资料（252 vs 126 笔） |
| 08-13 | 评估设计新增 5 折滚动原点交叉验证 | 单次 hold-out 可能被运气误导 |
| 08-13 | 实际连线 NASA 拉取 A/B/C 三序列并完整分析 | 验证可行性、产出真实图表供团队对照 |
| 08-13 | Hunga Tonga 变数决定不纳入模型 | 真实资料核对未见讯号，诚实呈现优于硬凑 |

---

## 21. 时间序列概念速查

### 21.1 定义
时间序列 = 按时间顺序排列的观测值。顺序即资讯，打乱顺序资讯就全毁。这个「前一期影响后一期」的性质叫自相关（Autocorrelation）。

### 21.2 四大成分
| 成分 | 定义 | 本案例子 |
|---|---|---|
| 趋势 Trend | 长期持续的上升或下降方向 | 复原趋势，但强度仅 0.17（偏弱） |
| 季节性 Seasonality | 周期固定且已知的重复波动 | 8 月生成、9–10 月最深、12 月消散，强度 0.90 |
| 循环 Cycle | 波动周期不固定、无法预知 | 可能的 QBO/ENSO 影响（§9.4 讨论） |
| 不规则 Irregular | 拆掉前三者后剩下的随机跳动 | 2019 SSW 造成的离群残差 |

### 21.3 加法 vs 乘法
加法：季节波动幅度固定。乘法：季节波动幅度随水平放大，取 log 可转成加法。

### 21.4 平稳性
统计性质不随时间改变。ARIMA 类模型假设平稳性。差分（一阶消除趋势、季节差分消除季节）是达成平稳的手段，但不要过度差分。

### 21.5 单位根检定（方向相反，务必写对）
| 检定 | H₀ | 通过标准 |
|---|---|---|
| ADF | 不平稳（有单位根） | p < 0.05 ✅ |
| KPSS | 平稳 | p > 0.05 ✅ |

### 21.6 ACF 与 PACF
ACF：总相关（含间接传导）。PACF：扣除中间期后的纯直接相关。

| 图形特征 | 建议模型 |
|---|---|
| ACF 拖尾，PACF 在 lag p 后截断 | AR(p) |
| ACF 在 lag q 后截断，PACF 拖尾 | MA(q) |
| 两个都拖尾 | ARMA(p,q)，用 AIC 挑 |
| ACF 在 lag 12,24,36 有尖峰 | 需加季节项 |

### 21.7 残差诊断
好的模型残差应为白噪音：平均≈0、无自相关、变异数固定。Ljung-Box 检定 H₀=无自相关，要 **p > 0.05** 才算通过（本案例 SARIMA 反而没通过，是重要的真实发现）。

---

## 22. 五个模型的技术规格

### 22.0 Seasonal Naïve（基准线）
`ŷₜ₊ₕ = yₜ₊ₕ₋ₘ`。零成本、零假设。§9.5 的真实结果显示这个基准线在滚动验证中出乎意料地难打败。

### 22.1 Holt-Winters / ETS（成员 A）
维护水平（α）、趋势（β）、季节（γ）三状态，加权更新。本案例真实拟合出现 α=1, γ=0 的退化解，代表水平项完全跟随最新观测、季节项未被更新——是重要的诊断发现，需在报告中讨论。阻尼趋势（φ<1）避免长期预测无限外推。不能加外生变数。

### 22.2 SARIMA（成员 B）
SARIMA(p,d,q)(P,D,Q)ₘ。Box-Jenkins 流程：视觉化→稳定变异数→差分→ACF/PACF 定阶→AIC 比较→残差诊断。**不要只贴 auto_arima 结果**——本案例的 auto_arima 选出的模型残差诊断未通过，网格搜索 40+ 组合后仍难找到白噪音残差，这本身是重要发现，暗示可能有非 12 月周期的物理驱动（如 QBO 准两年振荡）。

### 22.3 谐波回归 / TSLM+Fourier（成员 C）
`y ~ trend() + fourier(K)`，K=2~3。可解释性最强，趋势系数即复原速率的直接估计。本案例中 TSLM 在 hold-out 与滚动验证中表现最稳定，且在面积序列（m=6）上 RMSE 明显优于基准线（即使 MASE 相近），代表其对大误差的控制更好。

### 22.4 NNAR（成员 D）
类神经自回归，需 `set.seed()`。本案例用 MLP 代理模型在成员 A 序列上测试，MASE 达 2.52，明显劣于其他所有模型——在观测数偏少（240 笔训练）、序列噪音主导的情况下，类神经网络容易表现不佳。这是「模型能力强不代表表现好」的具体案例，务必写进个人报告的 Limitations。

