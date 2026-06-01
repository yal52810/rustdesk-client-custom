//! 二维矩阵竞速模块
//!
//! 三种连接模式：
//! - Auto: 所有中继 × 所有协议并发竞速，先通先用
//! - TcpOnly (专业版): 仅 TCP+ChaCha20，300ms 快速降级
//! - WssOnly (企业校园版): 仅 WSS+TLS，300ms 快速降级

use hbb_common::{config::Config, log, tokio};
use serde::{Deserialize, Serialize};
use std::time::Duration;

/// 用户可见的连接场景模式（不暴露协议术语）
#[derive(Clone, Copy, PartialEq, Debug, Serialize, Deserialize)]
pub enum ConnectionMode {
    /// 自动择优 (默认) — 并发竞速 TCP ∥ WSS
    Auto,
    /// 专业版 — 仅 TCP+ChaCha20，追求极致低延迟
    TcpOnly,
    /// 企业校园版 — 仅 WSS，追求绝对穿透率
    WssOnly,
}

impl Default for ConnectionMode {
    fn default() -> Self {
        ConnectionMode::Auto
    }
}

/// 连接协议（内部使用，不暴露给用户）
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum RelayProtocol {
    TcpEncrypted,
    Wss,
}

impl RelayProtocol {
    pub fn is_wss(&self) -> bool {
        matches!(self, RelayProtocol::Wss)
    }
}

/// 中继节点信息
#[derive(Clone, Debug)]
pub struct RelayNode {
    pub name: String,
    pub region: String,
    /// TCP 中继地址 (host:21117)
    pub relay_server: String,
    /// WSS 中继地址 (host:21119 或 wss://host:21119)
    pub ws_host: String,
    pub priority: i32,
    pub cost_weight: i32,
    pub support_wss: bool,
}

impl RelayNode {
    /// 获取指定协议的中继地址
    pub fn addr_for(&self, protocol: RelayProtocol) -> &str {
        match protocol {
            RelayProtocol::TcpEncrypted => &self.relay_server,
            RelayProtocol::Wss => &self.ws_host,
        }
    }
}

/// 竞速结果
pub struct RaceResult {
    pub node: RelayNode,
    pub protocol: RelayProtocol,
}

/// 获取连接模式（从用户配置读取）
pub fn get_connection_mode() -> ConnectionMode {
    let mode_str = Config::get_option("connection-mode");
    match mode_str.as_str() {
        "tcp-only" => ConnectionMode::TcpOnly,
        "wss-only" => ConnectionMode::WssOnly,
        _ => ConnectionMode::Auto,
    }
}

/// 从 admin API 或本地配置获取中继节点列表
pub async fn fetch_relay_server_list() -> Vec<RelayNode> {
    // 优先从 API 获取（冷启动时通过 /api/server-config-v2 已缓存）
    // 其次从 ConfigUpdate protobuf 推送获取（热更新）
    // 最后从本地配置 fallback
    let relay_server = Config::get_option("relay-server");
    if !relay_server.is_empty() {
        return vec![RelayNode {
            name: "default".to_owned(),
            region: "".to_owned(),
            relay_server: relay_server.clone(),
            ws_host: format!("{}:{}", relay_server.replace(":21117", ""), 21119),
            priority: 10,
            cost_weight: 1,
            support_wss: true,
        }];
    }
    vec![]
}

/// 自动择优 — 并发竞速
///
/// 同时向所有中继发起 TCP 和 WSS 探针，首个完成握手者胜出。
/// TCP 超时 500ms（少一次 TLS 握手），WSS 超时 800ms（多 TLS 握手）。
/// 公网环境 TCP 先通，公司防火墙环境 WSS 是唯一通的那个。
pub async fn race_concurrent(
    nodes: &[RelayNode],
) -> Result<RaceResult, String> {
    let mut tasks = Vec::new();

    for node in nodes {
        let node = node.clone();

        // 探针 A: TCP + ChaCha20 (500ms 超时)
        tasks.push(tokio::spawn(async move {
            let result = tokio::time::timeout(
                Duration::from_millis(500),
                connect_tcp_encrypted(&node.relay_server),
            )
            .await;
            result.map(|r| (node.clone(), RelayProtocol::TcpEncrypted, r))
        }));

        // 探针 B: WSS + TLS (800ms 超时)
        if node.support_wss && !node.ws_host.is_empty() {
            let node = node.clone();
            tasks.push(tokio::spawn(async move {
                let result = tokio::time::timeout(
                    Duration::from_millis(800),
                    connect_wss(&node.ws_host),
                )
                .await;
                result.map(|r| (node.clone(), RelayProtocol::Wss, r))
            }));
        }
    }

    // 收集首个成功的结果
    for task in tasks {
        if let Ok(Ok((node, proto, Ok(())))) = task.await {
            log::info!(
                "二维竞速胜出: 节点={}, 协议={:?}",
                node.name,
                proto
            );
            return Ok(RaceResult { node, protocol: proto });
        }
    }

    Err("所有中继线路和协议全部不可达".to_owned())
}

/// 专业版 / 企业校园版 — 快速降级逐个尝试
///
/// 300ms 超时逐个尝试节点，不通立刻切下一个。
/// 最省资源，适合已知网络环境下的极速连接。

pub async fn race_fallback_tcp(
    nodes: &[RelayNode],
) -> Result<RaceResult, String> {
    for node in nodes {
        let result = tokio::time::timeout(
            Duration::from_millis(300),
            connect_tcp_encrypted(&node.relay_server),
        )
        .await;

        if let Ok(Ok(())) = result {
            log::info!("TCP 快速降级选中: {}", node.name);
            return Ok(RaceResult {
                node: node.clone(),
                protocol: RelayProtocol::TcpEncrypted,
            });
        }
    }
    Err("所有 TCP 节点不可达".to_owned())
}

pub async fn race_fallback_wss(
    nodes: &[RelayNode],
) -> Result<RaceResult, String> {
    for node in nodes.iter().filter(|n| n.support_wss) {
        let result = tokio::time::timeout(
            Duration::from_millis(300),
            connect_wss(&node.ws_host),
        )
        .await;

        if let Ok(Ok(())) = result {
            log::info!("WSS 快速降级选中: {}", node.name);
            return Ok(RaceResult {
                node: node.clone(),
                protocol: RelayProtocol::Wss,
            });
        }
    }
    Err("所有 WSS 节点不可达".to_owned())
}

/// 探测探针：TCP + ChaCha20 连接
/// Phase 6 实现完整加密握手，目前做基础 TCP 连接探测
async fn connect_tcp_encrypted(addr: &str) -> Result<(), String> {
    use hbb_common::tcp::FramedStream;
    let addr = if !addr.contains(':') {
        format!("{}:{}", addr, 21117)
    } else {
        addr.to_owned()
    };
    // Phase 6: 替换为 EncryptedStream / ChaCha20 握手
    FramedStream::new(&addr, None, 500)
        .await
        .map(|_| ())
        .map_err(|e| format!("TCP connect failed: {}", e))
}

/// 探测探针：WSS 连接
/// Phase 6 实现完整 WSS 握手，目前做基础 TCP 连接探测
async fn connect_wss(addr: &str) -> Result<(), String> {
    use hbb_common::tcp::FramedStream;
    let addr = if !addr.contains(':') {
        format!("{}:{}", addr, 21119)
    } else {
        // strip wss:// prefix if present
        addr.replace("wss://", "")
    };
    // Phase 6: 替换为 WSS 握手
    FramedStream::new(&addr, None, 800)
        .await
        .map(|_| ())
        .map_err(|e| format!("WSS connect failed: {}", e))
}
