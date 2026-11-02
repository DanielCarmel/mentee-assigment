# Ship it: hello_world.py → the cloud

A greenfield Python microservice that ships itself to AWS on every version tag —
no manual steps. Push a SemVer git tag, and a versioned container image is built,
pushed, and deployed to ECS with a blue/green rollout.

## TL;DR flow

```
git tag v1.2.3 && git push origin v1.2.3
        │
        ▼
GitHub Actions  ──(OIDC, no secrets)──►  AWS
  1. run tests (gate)
  2. docker build --build-arg APP_VERSION=1.2.3
  3. push image to ECR  :1.2.3  +  :latest
  4. register ECS task definition
  5. CodeDeploy blue/green shift on the ALB (auto-rollback on failure)
```

The git tag is the single source of truth: it becomes the **image tag** and the
app's **APP_VERSION**, so the app version and image version always match. Verify
live with `GET /version`.

---

## Be ready to explain

### 1. Architecture: which AWS services, why, and how they connect

| Service | Role | Why |
| --- | --- | --- |
| **ECR** | Container registry | Private, IAM-native, lifecycle policy expires old images. |
| **ECS Fargate** | Runs the container | Serverless containers — no EC2 to patch; realistic microservice runtime. |
| **ALB** | Public entry point | Stable DNS, health checks, and the traffic-shifting device for blue/green. |
| **CodeDeploy** | Blue/green deploys | Native ECS blue/green with automatic rollback on failed health checks. |
| **IAM + GitHub OIDC** | Keyless CI auth | GitHub Actions assumes an IAM role via OIDC — no long-lived AWS keys. |
| **S3** | Terraform state | Durable remote state that survives ephemeral CI/CloudShell sessions. |
| **CloudWatch Logs** | Task logs | Centralised logs + container insights. |

**How they connect:** a `v*.*.*` tag triggers GitHub Actions, which assumes the
`exam-github-actions` role via OIDC, builds the image, pushes to **ECR**, registers
a new **ECS** task definition, and calls **CodeDeploy**. CodeDeploy launches the new
(green) tasks, health-checks them through the **ALB**, shifts traffic, and tears
down the old (blue) tasks — rolling back automatically if health checks fail.

### 2. Builds: making the workflow and image build faster

- **Docker layer caching in CI** — the build uses GitHub Actions cache
  (`cache-from/to: type=gha`). Dependencies are installed before app code is copied,
  so a code-only change reuses the cached `pip install` layer and rebuilds in seconds.
- **Multi-stage build** — deps are built in a builder stage; the runtime image only
  carries the venv + app, keeping the image small and pulls fast.
- **Slim base image** (`python:3.12-slim`) — smaller surface, faster pull/push.
- **Further options:** build ARM/Graviton images (cheaper/faster on Fargate),
  pre-warm the GHA cache, or move to a buildkit remote cache shared across runs.

### 3. Exposing the service: how users reach it, and who should

- **How:** users hit the **ALB's public DNS** on port 80 (→ 443 with ACM TLS in prod).
  The ALB health-checks `/health` and forwards to Fargate tasks on port 8000.
- **Network isolation:** the task security group only accepts traffic **from the ALB
  security group** — users never reach the container directly.
- **Who should:** today the ALB is open (`0.0.0.0/0`) for the demo. To restrict:
  narrow the ALB SG to specific CIDRs, add **AWS WAF**, require auth (Cognito/OIDC
  on the ALB), or make the ALB internal and front it with a VPN/private link.

### 4. The hard parts

- **Locked-down exam account:** no local AWS credentials and no permission to create
  access keys. Solved by running Terraform from **CloudShell**, which is already
  authenticated as the exam user.
- **IAM boundaries:** every role must be named `exam-*` and carry the
  `candidate-exam-boundary`. The user also can't create an OIDC provider, so the
  code **references the pre-existing** GitHub OIDC provider via a data source.
- **OIDC subject mismatch:** this GitHub org appends immutable numeric IDs to the
  token `sub` (`repo:Org@<id>/repo@<id>:*`). The role trust policy had to match that
  exact pattern — found via CloudTrail after the first `AccessDenied`.
- **CloudShell 1 GB home:** three Terraform units each pulling the AWS provider blew
  the disk. Fixed with a shared `TF_PLUGIN_CACHE_DIR` and `--download-dir` in `/tmp`.

### 5. Production: what I'd add before real traffic

- **TLS/HTTPS** via ACM + an HTTPS listener; redirect 80→443.
- **Autoscaling** on CPU/requests; run ≥2 tasks across AZs.
- **Observability:** structured logs, metrics, alarms, tracing (X-Ray/OTel).
  Wire CloudWatch alarms into CodeDeploy so deploys roll back on error-rate spikes.
- **Security:** WAF, image scanning gate, least-privilege task role, secrets in
  Secrets Manager, private subnets + NAT (no public task IPs).
- **Deploy safety:** canary/linear traffic shifting instead of all-at-once;
  smoke tests as CodeDeploy lifecycle hooks.
- **Supply chain:** pin digests, SBOM, image signing (cosign).

### 6. Infra as code: how it's all created automatically

Everything is **Terraform + Terragrunt** with reusable modules:

```
infra/
├── root.hcl                      # provider, versions, S3 backend, common inputs
├── modules/
│   ├── tfstate-backend/          # S3 state bucket (versioned, encrypted, private)
│   ├── ecr/                      # repository + lifecycle policy
│   ├── github-oidc/              # exam-github-actions role (keyless CI)
│   └── ecs-service/              # cluster, task, service, ALB, SGs, CodeDeploy
└── live/eu-west-2/               # thin Terragrunt units wiring modules + deps
    ├── tfstate-backend/
    ├── ecr/
    ├── ecs-service/
    └── github-oidc/
```

Terragrunt resolves the dependency graph (ecr → ecs-service → github-oidc) and keeps
each unit's state under its own key in S3.

---

## Bootstrap (AWS CloudShell, eu-west-2)

```bash
# 1. Install latest terraform + terragrunt into ~/bin (ephemeral shell)
mkdir -p ~/bin && export PATH="$HOME/bin:$PATH"
TF_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
curl -sSo /tmp/tf.zip "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip"
unzip -o /tmp/tf.zip -d ~/bin && rm /tmp/tf.zip
TG_VER=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
curl -sSLo ~/bin/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/v${TG_VER}/terragrunt_linux_amd64"
chmod +x ~/bin/terragrunt

# 2. Clone
git clone https://github.com/DanielCarmel/mentee-assigment.git
cd mentee-assigment/infra/live/eu-west-2

# 3. Keep provider cache off the 1 GB home quota
mkdir -p /tmp/tf-plugin-cache /tmp/tg-cache
export TF_PLUGIN_CACHE_DIR=/tmp/tf-plugin-cache

# 4. Create the state bucket first (uses local state)
terragrunt apply --working-dir tfstate-backend --download-dir /tmp/tg-cache

# 5. Apply the rest (S3 state)
terragrunt run --all apply --queue-exclude-dir tfstate-backend --download-dir /tmp/tg-cache
```

## Release

```bash
git tag v1.0.0 && git push origin v1.0.0     # CI builds, pushes, deploys
curl http://<alb-dns-name>/version            # -> {"version":"1.0.0"}
```

## Rollback

- **Automatic:** a failed health check during a deploy triggers CodeDeploy
  auto-rollback to the previous (blue) version.
- **Manual:** re-deploy the previous ECS task-definition revision, or stop and roll
  back the active deployment from the CodeDeploy console.
