# cnb-lifecycle-task

example

```yaml
resources:
- name: lifecycle
  type: git
  source:
    uri: https://github.com/making/cnb-lifecycle-task.git
    branch: main
- name: repo
  type: git
  source:
    uri: https://github.com/making/sample-java-app.git
- name: builder
  type: docker-image
  source:
    repository: paketobuildpacks/builder
    tag: base
jobs:
- name: build-image
  plan:
  - in_parallel:
    - get: workspace
      resource: repo
      trigger: true
    - get: builder
    - get: lifecycle
  - task: creator
    image: builder
    params:
      DOCKER_IMAGE: ((docker_image))
      DOCKER_USERNAME: ((docker_username))
      DOCKER_PASSWORD: ((docker_password))
    file: lifecycle/creator.yml
```
