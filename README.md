# Helm common chart


## Introduction

As a platform team, our goal is to modernize the management of Kubernetes resources and deployments. We aim to empower teams by providing:
- An abstraction layer on top of Kubernetes templates.
- A straightforward method for managing team-specific Kubernetes resources.
- Streamlined processes for Kubernetes deployment.
- Effective management of application deployments and Kubernetes resource changes.
- Adherence to GitOps principles.

This repository outlines our approach to utilizing Helm as a Kubernetes resource manager for teams. Please note that work on this repository is currently in active progress. 


## What is Helm?

Helm is a package manager for Kubernetes that simplifies the deployment and management of applications and services. It provides a way to package Kubernetes resources into reusable, versioned charts, making it easier to share, install, and manage complex applications.

Key features of Helm include:
- Charts: Helm packages are called charts, which contain all the Kubernetes resources necessary to run an application, including deployments, services, and config maps. Charts can be versioned, shared, and reused across different environments.
- Templating Engine: Helm uses Go templates to generate Kubernetes manifests dynamically. This allows for parameterization and customization of charts based on different environments or configurations.
- Dependency Management: Helm supports dependency management, allowing charts to depend on other charts. This simplifies the management of complex applications with multiple components or dependencies.
- Release Management: Helm manages releases of applications deployed to Kubernetes clusters. This includes installing, upgrading, rolling back, and deleting releases, making it easy to manage the lifecycle of applications.
- Repository: Helm charts can be stored in repositories, which can be public or private. Public repositories like the official Helm Hub provide a wide range of curated charts for popular applications, while private repositories allow organizations to manage their own charts internally.
- Hooks and Post-install Actions: Helm supports pre-installation and post-installation hooks, enabling additional actions or configurations before or after installing a chart.
- Security: Helm supports RBAC (Role-Based Access Control).

Overall, Helm simplifies the management of Kubernetes applications by providing a standardized way to package, distribute, and manage applications across different environments. It has become a popular tool in the Kubernetes ecosystem for streamlining the deployment workflow and promoting best practices in managing Kubernetes resources.
More information can found here: https://helm.sh.


## Pros and cons

### Pros

- Grouping related Kubernetes manifests into a single entity (the chart), providing a unified definition for all resources covering specific functionality (microservice or application).
- Templating and value configuration for Kubernetes manifests. It's recommended to utilize pre-defined templates with logic and variables at different levels for enhanced customization.
- Declaration of dependencies between applications (chart of charts), which is a crucial aspect we'll leverage extensively. This enables the creation of charts with dependencies on other charts, commonly known as umbrella or common charts, which are managed by the platform team.
- A holistic view of a Kubernetes cluster at the application/chart level.
- Streamlined management of chart installation/upgrades as a cohesive unit.
- Helm seamlessly integrates with CD tools such as ArgoCD, facilitating automated deployment workflows.

### Cons:
- Setting up Helm and understanding its charts, templates, and values files can require a learning curve.
- No good native way to manage kubernetes secrets. 
- Helm's error handling capabilities are limited, making it challenging to troubleshoot and diagnose issues during deployment.


## Common chart structure

As mentioned, the platform team does not expect teams to manage their own charts from scratch. Instead, we encourage teams to use a pre-created common chart from this repository as a dependency. In the ideal scenario, the end team shall only need to create a small chart that includes the needed templates (maintained by the platform team) and provide the required variables in the values file. This simplifies and abstracts the interaction with Kubernetes clusters for the end teams and shifts all the complexity of the templates to the platform team, which has the resources and knowledge to support it.
The common chart maintainer (Platform team) defines a common chart as a library chart and is confident that Helm will handle the chart in a standard consistent fashion across the entire company.

Now it comes to the structure of the common chart. The main parts are:
1. Chart.yaml
Here, the main information about the common chart is defined - name, type (library, not application), and version. Name and version are important to provide for dependency.

2. templates directory. 
Contains all the template files written in the Go template language. These templates are used to generate Kubernetes YAML manifests dynamically during the Helm deployment process. It is up to the platform team to add/maintain templates that can be reused by end teams.

3. templates/libs directory.
A library chart is a type of Helm chart that defines chart primitives or definitions which can be shared by Helm templates in other charts. This allows users to share snippets of code that can be reused across charts, avoiding repetition and keeping charts [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).


## Common chart usage
Using the common chart is relatively easy. As prerequisites:
- Access to the Kubernetes cluster or Minikube must be granted.
- Helm and kubectl must be installed.

How to use common chart:
1. Navigate to the directory where you want to create the Helm chart. This directory could be within application repository or in a separate Helm repository. Once in the desired directory, use the following command to create a chart named after your application:

`helm create simple-app`

2. Delete everything in template directory (we don't need it)

`rm -rf simple-app/templates/*`

Also all content from values.yaml file can be deleted, we don't need everything there.

3. Change content of Chart.yaml to add dependency to common-chart

```
dependencies:
- name: common-chart
  version: {CURRENT COMMON CHART VERSION}
  repository: {COMMON CHART PATH/ECR REPO}
```

Note: unfortunately, helm does not support git repo as dependency. It is possible to use local path or ECR repo as dependency. 
- with local path dependency case, clone common chart repo locally and reference it via `file://{PATH}/common-chart`
- consult with Platform team if they have common-chart available in ECR. If so, it could be referenced as `oci://{ECR_REPO}/common-chart`. Don't forget to log to the ECR before using it.

4. Test if common-chart dependency works

`cd simple-app; helm dependencies update .`

5. Create simple-app chart by creating simple-app.yaml in `templates` directory. Add templates that shall be used to build application in Kubernetes. For example, if appication has deployment, service and ingress, then configuration looks as simple as that:

```
{{- include "common-chart.service" . }}
---
{{- include "common-chart.deployment" . }}
---
{{- include "common-chart.ingress" . }}
```

6. Supply values.yaml with required variables and values. Supported variables as well as list of templates can be found here (TODO).

7. Install/upgrade chart to kuberneter cluster/minikube.

`cd simple-app; helm upgrade --install simple-app . --debug`

8. Take a look to the example directory for simple-app example.


## Integration with ArgoCD - TODO


## Best practices

It is worth to recommend following best practices when using common Helm chart:

1. Use one Chart for all environments. That comes together with principle of running the same setup for all environments with different values.
2. Do proper variables leveling. Applying the DRY (don’t repeat yourself) principle implies that teams can only store the overrides in environment-specific configuration files values.{ENV}.yml and use default settings from values.yml. Helm supports this out of the box by allowing multiple values files parameters

`helm install mychart . -f values.yaml -f {PATH}/values.dev.yaml`
