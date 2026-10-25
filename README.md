# Service template

A starting point for a service that runs on the platform. You bring the application and its
`Dockerfile`; the platform brings the pipeline, the cluster configuration and the checks. You do not need
to know Kubernetes.

---

## Get a service running

### 1. Create your repository

Click **Use this template**, then **Create a new repository**.

### 2. Run **Setup service**

Open the **Actions** tab, choose **setup-service**, click **Run workflow**, and fill in the form:

| Field | Meaning | Default |
|---|---|---|
| name | Service name: lowercase letters, digits, dashes | none |
| port | Port your application listens on | 8080 |
| path | URL prefix: `/` for the whole site, `/api` for a sub-path | `/` |
| health | A path that returns 200 when the app is ready | `/` |
| database | Create a Postgres database for the service | no |
| image | Image repository | `ghcr.io/<owner>/<repository>` |

The workflow writes `deploy/service.yaml` and commits it. It checks every value and tells you what is
wrong if one is not valid.

### 3. Do the two steps it prints

The summary of the run lists two steps the workflow cannot do for you (it has no right to change
repository settings or to touch other repositories):

1. Run two `gh api` commands once, so the release workflow may open and merge its pull request.
2. Add one entry for your service to the platform repository and open a pull request there.

### 4. Push your application

Add your code and a `Dockerfile` at the repository root, then push to `main`. The pipeline tests it, builds
the image for amd64 and arm64, checks both, and releases it. After the platform has picked up the change,
your service answers on its URL.

---

## What happens on every push to `main`

| Step | What it does |
|---|---|
| Tests | Runs `scripts/test.sh` if you have one (a warning appears if you do not) |
| Build | Builds and publishes the image, tagged with the commit |
| Verify | Checks that every image runs on amd64 and arm64 |
| Release | Opens a pull request that changes the image tag in `deploy/service.yaml`, comments with what changed and how to roll back, and merges it |
| Deploy | The platform notices the change and deploys it, then runs a smoke test |

To roll back, open the release pull request and click **Revert**. Merge the revert pull request.

---

## What you can change

| You want to | You do |
|---|---|
| Change a port, path, health check or the database | Edit `deploy/service.yaml` in a pull request |
| Add a second component | Add an entry under `components:` and put its `Dockerfile` in a folder with the component's name |
| Run tests in the pipeline | Add `scripts/test.sh` |

Do not edit the `tag:` lines. The pipeline owns them.

## Limits

- One image per component. A component's `Dockerfile` is at the repository root when there is one
  component, or in `<component>/Dockerfile` when there are several.
- The pipeline files are a copy of the platform's current version. If the platform improves them, existing
  services have to take the change by hand.
- Security scanning, signing and secret management are not part of this template yet.
