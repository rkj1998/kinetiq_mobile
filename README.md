# ⚡ Kinetiq (`kinetiq_mobile`) — Antigravity Edition

> **Mobile-first, next-generation autonomous AI agent application for Android, iOS, and Windows desktop.**  
> Blending Google Antigravity simplicity and Apple UX elegance with edge inference speed, encrypted local memory, and autonomous web browsing.

---

## 🌌 Project Vision & End Goal

Commercial mobile AI clients are typically locked into proprietary backend silos, cloud data logging, slow round-trips, and rigid personas. 

**Kinetiq** solves this with five core pillars:
1. **Google Antigravity Simplicity & Apple UX Polish:** Clean, airy, zero-friction default aesthetic (`ThemeStyle.antigravityLight`) with soft elevated cards, modern typography, floating dock pills, and interactive kinetic graphics.
2. **Infinite Customization & Agent Soul:** Customize your agent's name (e.g. *Antigravity, Nova, Jarvis*), temperament, and custom backstory directives.
3. **Local Private Memory Bank:** Store encrypted user profile facts, preferences, and standing directives on-device. Memory context is injected directly into every ReAct execution loop.
4. **Grok Bot & Muse Teammate Model (A Computer of Its Own):** Bots operate as autonomous teammates that don't stall when you step away. They run multi-step workflows end-to-end on their own cloud VM browser runtime and pause for user approval on high-consequence operations (sending emails, making purchases).
5. **Zero-Central-Server BYOK & LAN Edge Inference:** Connect directly to cloud LPUs (Groq, OpenRouter, OpenAI) or local LAN host machines running Ollama / vLLM (`http://10.0.2.2:11434/v1` for Android Emulator or `http://192.168.x.x:11434/v1` over Wi-Fi).
6. **Local ReAct Autonomous Runtime & Embedded Browser:** In-app Reason-Act agent loop using OpenAI function calling to autonomously browse websites, search DuckDuckGo, extract web pages, and inspect pages live in `flutter_inappwebview`.

---

## 👥 Grok Bot & Muse Autonomous Teammate Capabilities

Kinetiq incorporates the operational paradigms introduced by **Grok Bot** and **Muse**:

* **A Computer of Its Own (Isolated Runtime):** Bots run jobs on an isolated runtime environment (`AutonomousCloudVMTool`), so jobs do not stall when you switch apps or step away.
* **Message Like a Teammate:** Hand off complex tasks (e.g., *"Scrape competitor pricing, summarize key shifts, draft follow-up email"*) directly in chat or via the **Teammate Workspace**.
* **Safety Vault & User Approvals:** High-risk actions (purchases, outbound emails, account modifications) automatically pause for explicit human sign-off via interactive action cards before executing.
* **Multi-Bot Parallelism:** Assign specialized lanes to different teammates (e.g. Antigravity as Chief of Staff, Cipher for Cyber Recon, Titan for Code Fixes).
* **Workflows Saved as Routines:** Bots learn your preferences and edge cases, saving workflows as reusable routines that run faster next time without re-explaining.
* **Friendly Bitmoji Companion Aesthetics:** Lively animated Bitmoji companion graphics with expressive blinking eyes, blush cheeks, and floating antigravity halos replacing rigid geometric glyphs.

---

## 🏗 System Architecture

```mermaid
flowchart TD
    User["User Prompt / Query"] --> Memory["AgentMemory Context Injection"]
    Memory --> AgentLoop["ReActAgent Loop (react_loop.dart)"]
    AgentLoop -->|1. Reason / Tool Choice| LLMAdapter["OpenAIAdapter (openai_adapter.dart)"]
    LLMAdapter -->|Inference Call| Endpoint["Neural Endpoint (Groq / Ollama / OpenRouter)"]
    Endpoint -->|tool_calls| LLMAdapter
    LLMAdapter -->|Tool Request| ToolRegistry["ToolRegistry (tool_registry.dart)"]
    
    subgraph Tools ["Local & Web Tool Suite"]
        ToolRegistry --> TimeTool["GetSystemTimeTool"]
        ToolRegistry --> WebSearch["WebSearchTool (DuckDuckGo HTML)"]
        ToolRegistry --> WebPage["FetchPageTextTool (Raw Scraper)"]
    end
    
    Tools -->|Result String| ToolRegistry
    ToolRegistry -->|Observation Feedback| AgentLoop
    AgentLoop -->|2. Final Answer| UI["KinetiqChatScreen (Theme-Aware)"]
    UI -.->|Inspect cited links| InAppBrowser["AgentBrowserSheet (flutter_inappwebview)"]
```

---

## 🎨 Theme & Visual Palette Engine

Kinetiq provides a multi-theme architecture controlled via `lib/models/app_theme_config.dart` and customizable in real-time inside the **Customization Studio**:

| Theme Mode | Style | Palette | Description |
| :--- | :--- | :--- | :--- |
| **Google Antigravity** *(Default)* | Clean Light | Paper White (`#F8FAFC`), Google Blue (`#1A73E8`) | Minimalist, airy, modern Google & Apple clean surfaces with soft shadows |
| **Antigravity Nebula** | Modern Dark Slate | Midnight Slate (`#0F172A`), Cyan/Indigo (`#6366F1`) | Gentle, soothing dark slate that is easy on the eyes (not pitch-black) |
| **Obsidian OLED** | Deep Black | Pure Black (`#050508`), Vivid Neon Glow | True zero-light black optimized for OLED displays and maximum contrast |
| **Cyber Titanium** | Metallic Zinc | Space Zinc (`#18181B`), Frosted Titanium | Apple space-gray and frosted metal aesthetics |

**Accent Color Palettes:** Google Blue, Quantum Violet, Emerald Mint, Amber Glow, Rose Quartz, Cyan Neon.

---

## 🤖 Animated Personas & Soul Customization

Each persona includes prompt conditioning, facial optics, and reactive orbital physics:

| Persona | Archetype | Color Scheme | Specialization |
| :--- | :--- | :--- | :--- |
| **Antigravity** *(Default)* | *Quantum Elegance* | Google Quantum Blue (`#1A73E8`, `#4285F4`) | Graceful reasoning, thoughtful responses, clean Google simplicity |
| **Muse** | *Hyper-Creative* | Violet & Rose Glow (`#8B5CF6`, `#EC4899`) | Autonomous browsing, visual reasoning, creative workflows |
| **Titan** | *Deep Reasoning* | Cobalt & Cyan Glow (`#3B82F6`, `#06B6D4`) | Software engineering, systems architecture, deep code synthesis |
| **Cipher** | *Autonomous Scout* | Emerald & Neon Mint (`#10B981`, `#14B8A6`) | Cyber recon, live web scraping, factual source verification |
| **Spark** | *High Velocity* | Amber & Flame Glow (`#F59E0B`, `#EF4444`) | Crisp briefings, instant bulleted productivity, quick action |

---

## 🧠 Memory Bank & Customer Data Context

Persistent, encrypted memory managed by `lib/models/agent_memory.dart` and `SecureKeyStore`:
- **User Identity:** Remembers the user's name and background bio/work role.
- **Fact Bank:** User-defined and agent-remembered facts categorized by *Preferences, Workstyle, Project, or General*.
- **Standing Directives:** Injected into every ReAct system prompt:
  ```text
  [PERSISTENT AGENT MEMORY & USER CONTEXT]
  - User Name: Alex
  - User Profile: Senior Software Architect
  - Standing Directives: Provide direct, elegant code. Prefer concise answers.
  - Remembered Facts:
    * [Preferences] Prefers Dart and Kotlin
    * [Workstyle] Values high execution velocity and verified sources
  [END OF MEMORY CONTEXT]
  ```

---

## 🔐 Security & Keystore Architecture

- **Hardware-Backed Encryption:** All API keys and sensitive endpoint tokens are stored on device using `flutter_secure_storage` with Android `EncryptedSharedPreferences` (AES-256 GCM backed by Android Keystore).
- **Zero Cloud Leakage:** No API keys are committed to Git, logged to consoles, or routed through any intermediary proxy servers.
- **Cleartext LAN Support:** Android manifest is pre-configured with `usesCleartextTraffic="true"` and network state permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`) to allow local HTTP inference against Ollama on LAN/Wi-Fi (`192.168.x.x` or emulator loopback `10.0.2.2`).

---

## 📁 Repository Directory Structure

```text
kinetiq_mobile/
├── android/                   # Android native wrapper & Gradle build scripts
│   ├── app/src/main/
│   │   └── AndroidManifest.xml # Internet, network state & cleartext permissions
│   └── settings.gradle.kts    # AGP 8.11.1 & Kotlin 2.2.20 configured
├── lib/
│   ├── main.dart              # Main entry point, dynamic theme provider & chat screen
│   ├── models/
│   │   ├── agent_character.dart # Persona definitions & soul customization
│   │   ├── agent_memory.dart    # Encrypted memory bank & prompt context model
│   │   ├── app_theme_config.dart# Google Antigravity, Nebula & Obsidian theme engine
│   │   └── endpoint_config.dart # Endpoint presets (Groq, Ollama LAN, OpenRouter)
│   ├── services/
│   │   ├── agent/
│   │   │   └── react_loop.dart  # Autonomous Reason-Act execution engine
│   │   ├── llm/
│   │   │   └── openai_adapter.dart # OpenAI-compatible Chat Completions client
│   │   ├── storage/
│   │   │   └── secure_key_store.dart # EncryptedSharedPreferences keystore
│   │   └── tools/
│   │       ├── base_tool.dart      # Abstract BaseTool specification
│   │       ├── mock_time_tool.dart # Local device timestamp tool
│   │       ├── tool_registry.dart  # Schema generator & tool dispatcher
│   │       └── web_tools.dart      # Web search & web page reader tools
│   └── widgets/
│       ├── agent_avatar.dart           # Custom-painted cyber-vector avatar
│       ├── agent_browser_sheet.dart    # Embedded in-app browser sheet
│       ├── antigravity_logo.dart       # Kinetic orbital antigravity logo
│       ├── antigravity_startup_modal.dart # Animated welcome and tour sheet
│       ├── character_selector_sheet.dart # Persona selection modal
│       ├── customization_studio_sheet.dart # Unified 4-tab studio (Soul, Memory, Look, Keys)
│       └── network_endpoint_sheet.dart   # BYOK / Neural endpoint configuration modal
├── test/
│   ├── agent_memory_test.dart # Unit tests for memory bank & context injection
│   ├── theme_config_test.dart # Unit tests for theme system & Material 3 generation
│   └── widget_test.dart       # Smoke test suite
├── windows/                   # Windows desktop runner & CMake build config
└── pubspec.yaml               # Flutter package configuration & material fonts
```

---

## 🚀 Getting Started & Local Setup

### 1. Install Dependencies & Verify
```bash
flutter pub get
flutter analyze
flutter test
```

### 2. Run on Target Platform
- **Android Emulator / Device:**
  ```bash
  flutter run -d emulator-5554
  ```
- **Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
