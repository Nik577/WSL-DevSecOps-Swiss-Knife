# WSL-DevSecOps-Swiss-Knife

[ [English](#english) | [Русский](#russian) ]

---

<a name="english"></a>
## English Version

### Overview
WSL-DevSecOps-Swiss-Knife is a standardized infrastructure-as-code (IaC) and security auditing environment optimized for Windows Subsystem for Linux 2 (WSL2). It automates the provisioning of a Cloud-Native toolset, allowing engineers to simulate production deployment patterns and security assessments within a local sandboxed environment.

### Technical Specification
The environment utilizes the **asdf** runtime version manager to maintain consistency across binary versions.

| Component | Technical Definition | Purpose |
| :--- | :--- | :--- |
| **Native Docker** | Containerization Runtime (OCI-compliant) | Provides OS-level virtualization for microservices isolation. |
| **k3d (K3s)** | Lightweight Kubernetes Distribution | Orchestrates containerized workloads and cluster lifecycle management. |
| **OpenTofu** | IaC Provisioning Tool | Manages infrastructure resources through declarative configuration files. |
| **Ansible** | Configuration Management Engine | Automates system configuration and application deployment state. |
| **Trivy** | Vulnerability Scanner | Performs static and dynamic analysis of container images and clusters. |
| **Gitleaks** | Secret Detection Tool | Identifies hardcoded secrets and credentials in version control history. |
| **k9s** | Kubernetes Terminal Interface | Provides real-time cluster observability and resource management. |

### Infrastructure Architecture (Deep Dive)

#### 1. Cluster: `devsecops-lab`
A single-node Kubernetes cluster powered by **k3d**. It encapsulates the entire testing environment, providing a CNCF-certified API for workload management.

#### 2. Nodes (The Infrastructure Layer)
- **k3d-devsecops-lab-server-0**: The **Control Plane** node. It runs the Kubernetes API server, scheduler, and controller manager. It is the "brain" that maintains the desired state of the cluster.
- **k3d-devsecops-lab-agent-0**: The **Worker** node. This node is responsible for running the actual application containers (Pods). It contains the Kubelet and Container Runtime.

#### 3. Pods (The Application Layer)
- **Namespace: `simulation`**
    - **juice-shop-xxxx**: The main target application. A microservice-based web store used for security testing.
- **Namespace: `kube-system`** (System Components)
    - **coredns**: Handles internal cluster DNS resolution.
    - **local-path-provisioner**: Manages dynamic persistent volume allocation on your local disk.
    - **metrics-server**: Collects resource usage data (CPU/RAM) for observability.

### Target Application: OWASP Juice Shop & Vulnerability Analysis

The lab environment focuses on identifying and mitigating modern web vulnerabilities.

#### Common Vulnerabilities Identified:
1.  **SQL Injection (SQLi)**: Unauthorized database access via input fields.
2.  **Broken Access Control**: Accessing administrative panels without proper clearance.
3.  **Insecure Dependencies**: Using outdated libraries with known CVEs (detected by Trivy).
4.  **Hardcoded Secrets**: Plaintext passwords or API keys in the source code (detected by Gitleaks).

#### Mitigation Strategies:
- **Shift Left Security**: Integrating scanners like **Trivy** and **Gitleaks** early in the development lifecycle.
- **Automated Patching**: Using **Ansible** or **Terraform** to update container images to patched versions.
- **Network Policies**: Implementing Kubernetes NetworkPolicies to restrict traffic between Pods.

### Learning Objectives and Scenarios

#### Scenario 1: Cluster Observability and Resource Management
**Objective**: Gain familiarity with Kubernetes resource hierarchy and real-time monitoring.
- **Execution**: Run `k9s`.
- **Navigation**:
    - Use `:ns` to filter by namespace. Select `simulation`.
    - Observe the `juice-shop` pod lifecycle.
    - Use `l` to inspect container logs for runtime errors.
- **Skills Gained**: Understanding of pod orchestration, namespace isolation, and troubleshooting via logs.

#### Scenario 2: Infrastructure Security Assessment
**Objective**: Identify security vulnerabilities within a running Kubernetes cluster.
- **Execution**: Run `trivy k8s --namespace simulation all`.
- **Observation**: Analyze the report for "CRITICAL" and "HIGH" vulnerabilities.
- **Skills Gained**: Proficiency in vulnerability management, risk assessment, and understanding of CVE (Common Vulnerabilities and Exposures).

#### Scenario 3: Secret Leak Detection
**Objective**: Prevent credential leakage in version control systems.
- **Execution**: Run `gitleaks detect -v`.
- **Observation**: Check for exposed API keys or private tokens in the local repository.
- **Skills Gained**: Implementation of DevSecOps best practices for secret management.

### Installation
```bash
curl -sSL https://raw.githubusercontent.com/Nik577/WSL-DevSecOps-Swiss-Knife/main/setup.sh | bash
```

---

<a name="russian"></a>
## Русская Версия

### Обзор проекта
WSL-DevSecOps-Swiss-Knife — это стандартизированная среда для реализации подходов Infrastructure-as-Code (IaC) и проведения аудита безопасности, оптимизированная для WSL2. Проект автоматизирует развертывание стека Cloud-Native инструментов, позволяя инженерам имитировать боевые сценарии деплоя и оценки безопасности в локальной изолированной среде.

### Техническое описание
Для обеспечения воспроизводимости среды используется менеджер версий **asdf**.

| Инструмент | Техническое определение | Назначение |
| :--- | :--- | :--- |
| **Native Docker** | Среда контейнеризации (OCI-compliant) | Виртуализация на уровне ОС для изоляции микросервисов. |
| **k3d (K3s)** | Дистрибутив Kubernetes | Оркестрация нагрузок и управление жизненным циклом кластера. |
| **OpenTofu** | Инструмент IaC | Управление ресурсами инфраструктуры через декларативные файлы. |
| **Ansible** | Система управления конфигурациями | Автоматизация настройки систем и деплоя приложений. |
| **Trivy** | Сканер уязвимостей | Статический и динамический анализ образов и конфигураций. |
| **Gitleaks** | Инструмент поиска секретов | Обнаружение захардкоженных учетных данных в истории Git. |
| **k9s** | Терминальный интерфейс K8s | Наблюдаемость (observability) и управление ресурсами кластера. |

### Архитектура инфраструктуры (Подробный разбор)

#### 1. Кластер: `devsecops-lab`
Локальный кластер Kubernetes на базе **k3d**. Он объединяет все компоненты среды, предоставляя стандартный API для управления нагрузками.

#### 2. Ноды (Уровень инфраструктуры)
- **k3d-devsecops-lab-server-0**: Нода **Control Plane** (Мастер-нода). Здесь работают API-сервер, планировщик и менеджеры контроллеров. Это «центр управления», поддерживающий состояние кластера.
- **k3d-devsecops-lab-agent-0**: Нода **Worker** (Рабочая нода). Отвечает за непосредственное выполнение контейнеров приложений (Подов). Содержит Kubelet и среду выполнения контейнеров.

#### 3. Поды (Уровень приложений)
- **Namespace: `simulation`**
    - **juice-shop-xxxx**: Основное учебное приложение. Веб-магазин с микросервисной архитектурой для тестов безопасности.
- **Namespace: `kube-system`** (Системные компоненты)
    - **coredns**: Отвечает за внутреннее разрешение имен (DNS) в кластере.
    - **local-path-provisioner**: Управляет динамическим выделением места на диске для данных.
    - **metrics-server**: Собирает данные о потреблении ресурсов (CPU/RAM).

### Учебная мишень: OWASP Juice Shop и анализ уязвимостей

Лаборатория ориентирована на выявление и устранение современных угроз веб-приложений.

#### Типовые выявляемые уязвимости:
1.  **SQL Injection (SQLi)**: Несанкционированный доступ к БД через поля ввода.
2.  **Broken Access Control**: Доступ к админ-панелям без авторизации.
3.  **Insecure Dependencies**: Использование устаревших библиотек с известными CVE (обнаруживается через **Trivy**).
4.  **Hardcoded Secrets**: Открытые пароли или API-ключи в коде (обнаруживается через **Gitleaks**).

#### Методы борьбы и предотвращения:
- **Shift Left Security**: Внедрение сканеров (**Trivy**, **Gitleaks**) на ранних этапах разработки.
- **Automated Patching**: Обновление образов контейнеров до безопасных версий с помощью **Ansible** или **OpenTofu**.
- **Network Policies**: Ограничение сетевого взаимодействия между подами через политики Kubernetes.

### Учебные сценарии и задачи

#### Сценарий 1: Наблюдаемость кластера и управление ресурсами
**Цель**: Изучить иерархию ресурсов Kubernetes и методы мониторинга в реальном времени.
- **Действие**: Запустить `k9s`.
- **Навигация**:
    - Используйте `:ns` для фильтрации по пространству имен. Выберите `simulation`.
    - Проанализируйте состояние пода `juice-shop`.
    - Используйте клавишу `l` для просмотра логов контейнера.
- **Результат**: Понимание принципов оркестрации подов, изоляции ресурсов и методов отладки.

#### Сценарий 2: Оценка безопасности инфраструктуры
**Цель**: Выявление уязвимостей в работающем кластере Kubernetes.
- **Действие**: Выполнить `trivy k8s --namespace simulation all`.
- **Анализ**: Изучите отчет на наличие уязвимостей уровней "CRITICAL" и "HIGH".
- **Результат**: Навыки управления уязвимостями, оценки рисков и понимание базы CVE.

#### Сценарий 3: Детекция утечки секретов
**Цель**: Предотвращение попадания конфиденциальных данных в системы контроля версий.
- **Действие**: Выполнить `gitleaks detect -v`.
- **Анализ**: Проверьте локальный репозиторий на наличие открытых API-ключей или токенов.
- **Результат**: Внедрение практик DevSecOps по безопасному управлению секретами.

### Быстрый запуск
```bash
curl -sSL https://raw.githubusercontent.com/Nik577/WSL-DevSecOps-Swiss-Knife/main/setup.sh | bash
```

---

**Разработано: [Nik577](https://github.com/Nik577)**
