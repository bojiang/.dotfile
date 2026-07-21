# 价值定位扫描 v2：基于信念筛选

**对象画像：** Qualcomm（经 Modular 收购入职），负责 K8s + model bring-up（AI 推理集群编排与模型部署）；坐标 San Jose；H-1B 身份（已计入 cap，走 change of employer）。

**数据截至：** 2026 年 7 月中

**v2 修订依据：**
1. ~~推理 serving~~ — 当前团队本身很强，跳到老对手没有意义。Baseten、Fireworks、Together AI、Hyperbolic 全部移除。
2. ~~做实事的 coding agent~~ — 面临 Anthropic（Claude Code）和 OpenAI 的直接威胁，降权。E2B、Runloop、Morph、Mechanize 等移除或降至观察。
3. 保留两类价值故事：
   - **Story A：To-B 不同生态位** — 企业级基础设施，被 agent 消费但不被 agent 替代（GPU 编排、K8s 平台、多云调度）
   - **Story B：弥合 agent→价值 gap** — agent 能力再强也需要评测、记忆、企业环境仿真才能交付业务价值（RL 训练环境、评测可观测、agent 记忆）

---

## 速览

| 价值故事 | 核心命题 | 代表公司 |
|---------|---------|---------|
| **A：不同生态位的 To-B 基础设施** | Agent 需要跑在某处；GPU 编排和 K8s 平台是 agent 的"水电煤"，不会被 Anthropic/OpenAI 替代 | CoreWeave、Nebius、GMI Cloud、SkyPilot、Anyscale、ScaleOps、Modal、Google GKE、AWS EKS、NVIDIA Run:ai |
| **B：弥合 agent→价值 gap** | Agent 能做事 ≠ 能交付业务价值；评测/记忆/企业环境仿真是 gap 的核心 | Prime Intellect、Fleet AI、Braintrust、Mem0、Cognee、LangSmith、Hamming |

---

## Story A：To-B 不同生态位 — Agent 的"水电煤"

> 逻辑：无论 coding agent 由谁做（Anthropic、OpenAI、还是别人），底层 GPU 编排、K8s 集群管理、多云调度的需求只增不减。这个生态位不会被上层 agent 吞掉。

### T0

#### CoreWeave（Nasdaq: CRWV）
- **定位：** 头部 neocloud；50,000+ GPU K8s 集群
- **融资/规模：** 已上市。2026 Q1 收入 $2.1B，同比 +112%；年底年化目标 $18B–$19B；backlog $99.4B
- **身份安全：** 非常高（上市公司）
- **技术匹配：** 非常高（超大规模 K8s GPU 编排）
- **商业机密距离：** 高

#### Nebius（Nasdaq: NBIS）
- **定位：** Neocloud（K8s、Slurm/Soperator、SkyPilot、Ray、Terraform）
- **融资/规模：** 已上市。微软合同 $17.4B+；2026 Q1 收入 $399M（+684% YoY）
- **身份安全：** 非常高
- **技术匹配：** 非常高
- **商业机密距离：** 高

#### GMI Cloud
- **定位：** San Jose GPU neocloud；自研 Cluster Engine 编排引擎；NVIDIA Reference Platform Cloud Partner
- **融资/规模：** $82M Series A；约 118 人。创始人 Alex Yeh（台湾背景）
- **身份安全：** 中（Series A，但本地化 + 积极招人）
- **技术匹配：** 非常高（Cluster Engine = 编排；地理一致）
- **语言加分：** 有（华人创始人 / 普通话团队）
- **商业机密距离：** 中（有自研推理引擎，但核心价值在编排层）
- **资本：** 台湾/泰国，非大陆
- **招聘：** Infrastructure Engineer – LLM Inference Optimization；ML Infra/SRE

#### Anyscale
- **定位：** Ray 背后的公司；托管分布式计算，覆盖训练、RL rollout 和 serving
- **融资/规模：** $100M Series C，估值 $1B；累计 ~$259M；~708 人
- **身份安全：** 高
- **技术匹配：** 非常高（Ray 是 RL rollout / 编排主流底座）
- **商业机密距离：** 中高（Ray Serve 有交叉，但平台远比 serving 宽）

#### SkyPilot
- **定位：** UC Berkeley Sky Computing Lab 衍生；跨 K8s/Slurm/20+ 云运行 AI 工作负载
- **融资/规模：** 种子轮（Coatue、Race Capital）
- **身份安全：** 低中（早期，但强 VC/Berkeley 背书）
- **技术匹配：** 非常高（多云 K8s 编排是完全匹配的技能）
- **商业机密距离：** 高
- **⚠ 注意：** 早期阶段的 H-1B runway 风险需权衡

#### Google Cloud — GKE-for-AI / Vertex AI
- **定位：** GKE 成为 AI 栈「中枢神经系统」（GPU/TPU 调度、Pod Snapshots）
- **身份安全：** 非常高（成熟 PERM 通道）
- **技术匹配：** 非常高
- **商业机密距离：** 中（Vertex 推理层有交叉，GKE 编排层无交叉）

#### AWS — EKS / Bedrock AgentCore
- **定位：** AgentCore = 无服务器 Agent 运行时；EKS Auto Mode + Ray Serve
- **身份安全：** 非常高
- **技术匹配：** 非常高
- **商业机密距离：** 中高

#### NVIDIA — Run:ai / KAI Scheduler / Grove
- **定位：** K8s GPU 编排核心产品方向；KAI Scheduler + Grove 管理多 Pod GPU serving
- **身份安全：** 非常高
- **技术匹配：** 非常高
- **语言加分：** 有（Lepton 团队华人核心）
- **商业机密距离：** 中（Run:ai/Grove 主攻编排）
- **⚠ 注意：** 贾扬清据报 2026 年 6 月离开，NVIDIA 未官方确认

### T1

#### Modal
- **定位：** Serverless Python 计算平台，gVisor 隔离 + GPU 支持
- **融资/规模：** $355M 融资，估值 $4.65B，年化收入 ~$300M
- **身份安全：** 高
- **技术匹配：** 高（大规模自动扩缩、GPU 编排）
- **商业机密距离：** 中高（平台比纯 serving 宽，但有 serving 重叠）

#### Crusoe
- **定位：** OpenAI Stargate 数据中心建设方；估值 ~$10B
- **身份安全：** 高
- **技术匹配：** 高
- **商业机密距离：** 高

#### Lambda
- **定位：** GPU 云；融资超 $1.5B，正筹备 IPO
- **身份安全：** 高
- **技术匹配：** 高
- **商业机密距离：** 高

#### Nscale
- **定位：** 英国 neocloud；$1.3B Series B，估值 $14.6B
- **身份安全：** 中（英国总部，美国岗位待核实）
- **技术匹配：** 高
- **商业机密距离：** 高

#### ScaleOps
- **定位：** K8s GPU 优化/自动调配层（分数 GPU 分配、持续 rightsizing）
- **身份安全：** 中（待核实）
- **技术匹配：** 非常高（纯 K8s GPU 调度）
- **商业机密距离：** 高

#### Microsoft Azure — AI Foundry Agent Service
- **定位：** 托管 Agent 运行时 + Agent365 治理控制面
- **身份安全：** 非常高
- **技术匹配：** 高
- **商业机密距离：** 高

#### Meta — PyTorch 基础设施
- **定位：** PyTorch 维护方，大规模训练/推理基础设施
- **身份安全：** 非常高
- **技术匹配：** 高
- **商业机密距离：** 中

#### Apple — ML 基础设施
- **定位：** 内部 ML 平台/基础设施团队
- **身份安全：** 非常高
- **技术匹配：** 中高
- **商业机密距离：** 高

### T2（观察）

- **Northflank** — 生产平台，月 200 万+ 隔离工作负载；K8s 原生多租户
- **Runpod / Vultr / Thunder Compute** — 身份安全各异

---

## Story B：弥合 Agent→价值 Gap

> 逻辑：Agent 能力（能写代码、能调 API）和业务价值交付之间存在巨大 gap。这个 gap 包括：agent 在真实企业环境中能否可靠工作？如何评估？如何让 agent 越来越好？填补这个 gap 的公司不会被 Anthropic/OpenAI 吞掉，因为这不是模型能力问题，是工程和场景问题。

### T0

#### Prime Intellect
- **定位：** 开放「超级智能栈」：去中心化 RL 训练、Environments Hub（2,500+ RL 环境）、评测、按需 GPU
- **融资/规模：** $130M Series A，估值 $1B（2026 年 7 月）；年化收入 $100M；6,000+ 客户
- **身份安全：** 中高
- **技术匹配：** 非常高（rollout 编排、GPU 集群、K8s）
- **商业机密距离：** 高
- **Story B 价值：** RL 训练环境是让 agent 从"能做事"到"做好事"的核心基础设施

#### Fleet AI
- **定位：** 为前沿实验室复制企业软件环境（Salesforce、Excel 等）的 RL 训练「健身房」
- **融资/规模：** 种子 ~$15M；正在谈 ~$50M+、估值 ~$750M 新一轮。年化收入从 ~$1M 增至 ~$60M
- **身份安全：** 中（新轮在谈）
- **技术匹配：** 高（仿真环境、编排）
- **商业机密距离：** 高
- **Story B 价值：** 直接解决"agent 在真实企业软件中能否工作"的问题。仿真 → 训练 → 可靠的企业 agent，这个链条是 gap 的核心

### T1

#### Braintrust
- **定位：** AI/Agent 评测 + 可观测性平台；CI/CD 质量门
- **融资/规模：** $80M Series B，估值 $800M；客户 Notion/Replit/Cloudflare/Ramp
- **身份安全：** 高
- **技术匹配：** 中（评测基础设施，集群比重低）
- **商业机密距离：** 高
- **Story B 价值：** 评测 = 你怎么知道 agent 真的在交付价值？没有评测就没有可靠性保证

#### Mem0
- **定位：** AI Agent 记忆层；开源（GitHub 41K+ star）；AWS Agent SDK 独家记忆提供方
- **融资/规模：** 种子 + Series A 合计 $24M
- **身份安全：** 中
- **技术匹配：** 中
- **商业机密距离：** 高
- **Story B 价值：** 无记忆的 agent 每次从零开始，永远无法积累上下文 → 无法交付持续价值

### T2（观察）

#### Cognee
- **定位：** 开源 Agent 记忆引擎（知识图谱）；$7.5M 种子轮。柏林总部
- **身份安全：** 低中
- **Story B 价值：** 同 Mem0，记忆是 gap 的一部分

#### LangChain / LangSmith
- **定位：** Agent 框架 + 可观测性；累计 $125M+
- **身份安全：** 高
- **技术匹配：** 中
- **Story B 价值：** 可观测性帮助诊断 agent 在哪里失败

#### Hamming AI
- **定位：** 语音和聊天 AI Agent 的 QA/测试平台；$4.5M 种子轮
- **身份安全：** 低
- **Story B 价值：** Agent 测试 = gap 的一部分，但规模太小

#### Chakra Labs
- **定位：** 开放 RL 环境平台，面向 computer-use agent
- **身份安全：** 低（待核实）
- **技术匹配：** 高
- **Story B 价值：** RL 环境，与 Prime Intellect / Fleet AI 同方向

---

## 已移除公司及理由

| 公司 | 原分层 | 移除理由 |
|------|-------|---------|
| **Baseten** | T1 | 推理 serving 直接竞品，当前团队更强 |
| **Fireworks AI** | T1 | 推理 serving 直接竞品 |
| **Together AI** | T1 | 推理 serving + GPU 集群，serving 是主业 |
| **Hyperbolic** | T2 | 推理市场 |
| **E2B** | T1 | Coding agent 沙箱，直接受 Anthropic/OpenAI 威胁 |
| **Runloop** | T2 | 专为 AI coding agent 构建，直接受威胁 |
| **Morph** | T2 | Code-apply 模型，直接受威胁 |
| **Mechanize** | T2 | 编码 agent RL 环境，直接受威胁 |
| **Daytona** | T1 | Agent 沙箱但主要服务 coding agent 生态 |
| **Blaxel** | T2 | Agent 沙箱，规模太小 + coding agent 关联 |
| **Zilliz** | T2 | 向量数据库，与核心技能匹配度低 + 有大陆资本 |
| **Alluxio** | T2 | 数据编排，与核心技能匹配度低 + 有大陆资本 |
| **SiliconFlow** | 标注 | 深度大陆资本 + 中国业务绑定 |

---

## v2 汇总分层表

| 分层 | Story A（不同生态位） | Story B（弥合 gap） |
|------|---------------------|-------------------|
| **T0** | CoreWeave、Nebius、GMI Cloud、Anyscale、SkyPilot（⚠ 早期）、Google GKE、AWS EKS、NVIDIA Run:ai | Prime Intellect、Fleet AI |
| **T1** | Modal、Crusoe、Lambda、Nscale、ScaleOps、Microsoft、Meta、Apple | Braintrust、Mem0 |
| **T2** | Northflank、Runpod 等 | Cognee、LangSmith、Hamming、Chakra Labs |

---

## 注意事项

- 估值/收入数据截至 2026 年 7 月中，部分为第三方估算
- Fleet AI 的 ~$750M 估值轮据报「在谈中」，未确认 close
- SkyPilot 商业实体视为种子阶段 + 强 VC/学术背书，H-1B runway 风险需独立评估
- GMI Cloud 有自研推理引擎，商业机密距离需个案评估（编排层安全，推理层有交叉）
- 贾扬清据报 2026 年 6 月离开 NVIDIA，待核实
