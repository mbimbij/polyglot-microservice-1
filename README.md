# Polyglot Microservices, #1

:fr: Sommaire / :gb: Table of Contents
=================

<!--ts-->

- [:fr: Description du projet](#fr-description-du-projet)
- [:gb: Project Description](#gb-project-description)

---

# :fr: Description du projet

Le but de ce projet est de s'essayer à implémenter un microservice "polyglotte": 

- 1 service en `NodeJS`
- 1 service en `Go`

Ainsi que d'élaborer la pipeline de CI/CD et la "plate-forme" de déploiement (si le terme est correct), typiquement quelque chose comme `Lambda`, `EKS`, et jeter éventuellement un oeil à `AppMesh`, voir si c'est intéressant.

Déploiement de la pipeline: 

`aws cloudformation deploy   --stack-name polyglot-app-pipeline-stack   --template-file infra/pipeline/pipeline-stack.yml   --capabilities CAPABILITY_NAMED_IAM   --profile dev   --parameter-overrides ApplicationName=polyglot-app GithubRepo=mbimbij/polyglot-microservice-1 KubernetesClusterName=demo-cluster-2`

Ajout au `mapRoles` pour effectuer `kubectl` depuis `CodeBuild` :

`kubectl edit configmap aws-auth -n kube-system`

Rajouter la valeur suivante

```yaml
    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/polyglot-app-kubectl-deploy-role
      username: kubectl-deploy-role
      groups:
        - system:masters
```

## pièges rencontrés

- il faut abréger le nom des rôles dans la configMap aws-auth
  - [https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/268](https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/268)
  - et la documentation n'aide pas: [https://aws.amazon.com/premiumsupport/knowledge-center/eks-api-server-unauthorized-error/](https://aws.amazon.com/premiumsupport/knowledge-center/eks-api-server-unauthorized-error/)

# :gb: Project Description

The goal of this project si to try to implement a "polyglot" microservice:

- 1 service in `NodeJS`
- 1 service in `Go`

And developping a CI/CD pipeline, along with a "deployment platform" (if the term is correct), basically something along the lines of `Lambda`, `EKS`, and have a look at `AppMesh` and see if it is interesting.
