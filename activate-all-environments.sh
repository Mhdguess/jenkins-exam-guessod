#!/bin/bash

# Script: activate-all-environments.sh
# Description: Active tous les environnements Kubernetes avec movie-service et cast-service

echo "🚀 ACTIVATION DE TOUS LES ENVIRONNEMENTS KUBERNETES"

# Fonction pour vérifier un environnement
check_environment() {
    local namespace=$1
    echo "📋 Vérification de l'environnement: $namespace"
    kubectl get pods -n $namespace 2>/dev/null || echo "⚠️ Namespace $namespace inaccessible"
}

# Fonction pour déployer dans un environnement
deploy_to_environment() {
    local namespace=$1
    local port_offset=$2
    local replicas=$3
    local image_policy=$4
    local db_name=$5
    
    echo "🎯 Déploiement dans: $namespace"
    
    cat > k8s-${namespace}.yaml << DEPLOYMENT
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${namespace}
spec:
  selector:
    app: movie-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: $((30000 + port_offset))
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${namespace}
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: movie-service
  template:
    metadata:
      labels:
        app: movie-service
    spec:
      containers:
      - name: movie-service
        image: guessod/movie-service-exam:exam-20
        imagePullPolicy: ${image_policy}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./${db_name}.db"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${namespace}
spec:
  selector:
    app: cast-service
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
      nodePort: $((30000 + port_offset + 1))
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${namespace}
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: cast-service
  template:
    metadata:
      labels:
        app: cast-service
    spec:
      containers:
      - name: cast-service
        image: guessod/cast-service-exam:exam-20
        imagePullPolicy: ${image_policy}
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///./${db_name}.db"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
DEPLOYMENT
    
    # Appliquer le déploiement
    kubectl apply -f k8s-${namespace}.yaml
    
    # Attendre le démarrage
    echo "⏳ Attente du démarrage dans ${namespace}..."
    sleep 30
    
    # Vérifier
    echo "📊 ÉTAT ${namespace}:"
    kubectl get pods,svc -n ${namespace}
}

# Étape 1: Vérifier l'état actuel
echo "🔍 ÉTAT ACTUEL DES ENVIRONNEMENTS:"
for ns in dev qa staging prod; do
    check_environment $ns
done

# Étape 2: Nettoyer les environnements non-dev
echo "🧹 Nettoyage des environnements..."
for ns in qa staging prod; do
    echo "  Nettoyage de $ns..."
    kubectl delete all --all -n $ns --ignore-not-found=true
    sleep 5
done

# Étape 3: Déployer dans tous les environnements
echo "🚀 DÉPLOIEMENT DANS TOUS LES ENVIRONNEMENTS..."

# QA - environnement de test
deploy_to_environment "qa" 11 1 "IfNotPresent" "qa"

# Staging - pré-production
deploy_to_environment "staging" 21 1 "IfNotPresent" "staging"

# Production - environnement de production
deploy_to_environment "prod" 1001 2 "Always" "prod"

# Étape 4: Vérification finale
echo "🎉 VÉRIFICATION FINALE:"
echo "========================================"

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null || echo "localhost")

for ns in dev qa staging prod; do
    echo ""
    echo "🌐 ENVIRONNEMENT: ${ns}"
    echo "📊 État:"
    kubectl get pods -n $ns 2>/dev/null | grep -E "movie|cast|NAME" || echo "   Pas de pods"
    
    # Récupérer les ports
    case $ns in
        "dev") PORT_MOVIE=30001; PORT_CAST=30002 ;;
        "qa") PORT_MOVIE=30011; PORT_CAST=30012 ;;
        "staging") PORT_MOVIE=30021; PORT_CAST=30022 ;;
        "prod") PORT_MOVIE=31001; PORT_CAST=31002 ;;
        *) PORT_MOVIE=30001; PORT_CAST=30002 ;;
    esac
    
    echo "🔗 Points d'accès:"
    echo "   Movie-service: http://${NODE_IP}:${PORT_MOVIE}/health"
    echo "   Cast-service:  http://${NODE_IP}:${PORT_CAST}/health"
done

# Étape 5: Nettoyage
echo ""
echo "🧹 Nettoyage des fichiers temporaires..."
rm -f k8s-qa.yaml k8s-staging.yaml k8s-prod.yaml 2>/dev/null || true

echo ""
echo "✅ TOUS LES ENVIRONNEMENTS SONT MAINTENANT ACTIFS !"
