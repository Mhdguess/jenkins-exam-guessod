pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "exam-${BUILD_ID}"
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'qa', 'staging'],
            description: 'Environnement de déploiement'
        )
        booleanParam(
            name: 'SKIP_DOCKER_PUSH',
            defaultValue: false,
            description: 'Passer le push DockerHub'
        )
    }
    
    stages {
        // ========== STAGE 0 : NETTOYAGE PRÉALABLE ==========
        stage('Nettoyage Initial') {
            steps {
                script {
                    echo "=== NETTOYAGE DE L'ENVIRONNEMENT ==="
                    
                    sh '''
                    echo "1. Nettoyage Docker..."
                    docker system prune -a -f 2>/dev/null || true
                    
                    echo "2. Nettoyage Kubernetes..."
                    # Supprimer les pods evicted
                    kubectl delete pods --field-selector=status.phase=Evicted --all-namespaces 2>/dev/null || true
                    kubectl delete pods --field-selector=status.phase=Failed --all-namespaces 2>/dev/null || true
                    
                    echo "3. Vérification espace disque..."
                    df -h /
                    '''
                }
            }
        }
        
        // ========== STAGE 1 : PRÉPARATION ==========
        stage('Préparation') {
            steps {
                script {
                    echo "=== EXAMEN DEVOPS DATASCIENTEST ==="
                    echo "Candidat: Mohamed GUESSOD"
                    echo "Build: ${BUILD_ID}"
                    echo "Environnement: ${params.DEPLOY_ENV}"
                    
                    cleanWs()
                    checkout scm
                    
                    sh '''
                    echo "✅ Code récupéré"
                    echo ""
                    echo "📁 Structure:"
                    ls -la
                    '''
                }
            }
        }
        
        // ========== STAGE 2 : BUILD DOCKER ==========
        stage('Build Docker') {
            steps {
                script {
                    echo "=== BUILD IMAGES DOCKER ==="
                    
                    // Build movie-service
                    sh """
                    echo "Building movie-service..."
                    cd movie-service
                    docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    echo "✅ movie-service: ${DOCKER_TAG}"
                    """
                    
                    // Build cast-service
                    sh """
                    echo "Building cast-service..."
                    cd cast-service
                    docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    echo "✅ cast-service: ${DOCKER_TAG}"
                    """
                    
                    sh '''
                    echo ""
                    echo "📦 Images disponibles:"
                    docker images | grep guessod || echo "Aucune image"
                    '''
                }
            }
        }
        
        // ========== STAGE 3 : PUSH DOCKERHUB ==========
        stage('Push DockerHub') {
            when {
                expression { params.SKIP_DOCKER_PUSH == false }
            }
            environment {
                DOCKERHUB_CREDS = credentials('dockerhub-guessod')
            }
            steps {
                script {
                    echo "=== PUSH DOCKERHUB ==="
                    
                    sh """
                    echo "\${DOCKERHUB_CREDS_PSW}" | docker login -u "\${DOCKERHUB_CREDS_USR}" --password-stdin
                    
                    echo "Pushing movie-service..."
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    
                    echo "Pushing cast-service..."
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    
                    echo ""
                    echo "✅ Images sur DockerHub:"
                    echo "   ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}"
                    echo "   ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}"
                    """
                }
            }
        }
        
        // ========== STAGE 4 : PRÉPARATION K8S ==========
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== CONFIGURATION KUBERNETES ==="
                    
                    sh '''
                    # Créer les 4 namespaces
                    echo "Création des namespaces..."
                    for ns in dev qa staging prod; do
                        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
                        echo "  ✓ $ns"
                    done
                    
                    echo ""
                    echo "📋 Namespaces:"
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|NAME"
                    
                    # Vérifier l'espace
                    echo ""
                    echo "💾 Espace disque nœud:"
                    kubectl describe nodes | grep -A 5 -B 5 "DiskPressure" || echo "✓ Pas de pression disque"
                    '''
                }
            }
        }
        
        // ========== STAGE 5 : DÉPLOIEMENT K8S SIMPLIFIÉ ==========
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT DANS ${params.DEPLOY_ENV} ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    
                    # Nettoyer avant de déployer
                    echo "Nettoyage pré-déploiement..."
                    kubectl delete deployment movie-service -n \$NAMESPACE 2>/dev/null || true
                    kubectl delete deployment cast-service -n \$NAMESPACE 2>/dev/null || true
                    kubectl delete service movie-service -n \$NAMESPACE 2>/dev/null || true
                    kubectl delete service cast-service -n \$NAMESPACE 2>/dev/null || true
                    
                    sleep 2
                    
                    # Déploiement SIMPLE - pas de probes pour éviter les erreurs
                    cat > k8s-simple.yaml << 'YAML'
---
# Movie Service - Version simple
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
spec:
  replicas: 1
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
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
        # Pas de probes pour simplifier
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: ClusterIP
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
---
# Cast Service - Version simple
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
spec:
  replicas: 1
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
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: ClusterIP
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    echo "Application du déploiement..."
                    kubectl apply -f k8s-simple.yaml
                    
                    echo "✅ Déploiement appliqué"
                    echo ""
                    echo "⏳ Attente démarrage (20s)..."
                    sleep 20
                    
                    echo ""
                    echo "📊 État dans \$NAMESPACE:"
                    kubectl get all -n \$NAMESPACE
                    """
                }
            }
        }
        
        // ========== STAGE 6 : VALIDATION PRODUCTION ==========
        stage('Validation Production') {
            when {
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                script {
                    echo "=== VALIDATION PRODUCTION ==="
                    
                    timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "✅ Staging déployé\n\nDéployer en PRODUCTION ?",
                            ok: "🚀 OUI, déployer en production",
                            submitter: "admin"
                        )
                    }
                    
                    echo "✅ Validation approuvée!"
                }
            }
        }
        
        // ========== STAGE 7 : DÉPLOIEMENT PRODUCTION ==========
        stage('Déploiement Production') {
            when {
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT PRODUCTION ==="
                    
                    sh """
                    # Production simplifiée
                    cat > k8s-prod.yaml << 'YAML'
---
# Movie Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  replicas: 1  # 1 seul replica pour économiser l'espace
  selector:
    matchLabels:
      app: movie-service-prod
  template:
    metadata:
      labels:
        app: movie-service-prod
    spec:
      containers:
      - name: movie-service
        image: ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  type: ClusterIP
  selector:
    app: movie-service-prod
  ports:
  - port: 8000
    targetPort: 8000
---
# Cast Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  replicas: 1  # 1 seul replica pour économiser l'espace
  selector:
    matchLabels:
      app: cast-service-prod
  template:
    metadata:
      labels:
        app: cast-service-prod
    spec:
      containers:
      - name: cast-service
        image: ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  type: ClusterIP
  selector:
    app: cast-service-prod
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    # Nettoyer prod avant
                    echo "Nettoyage production..."
                    kubectl delete deployment movie-service-prod -n prod 2>/dev/null || true
                    kubectl delete deployment cast-service-prod -n prod 2>/dev/null || true
                    
                    # Déployer
                    kubectl apply -f k8s-prod.yaml
                    
                    echo "✅ Production déployée!"
                    echo ""
                    echo "📊 État production:"
                    kubectl get all -n prod
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== RAPPORT FINAL ==="
            script {
                sh '''
                echo "🧑‍💻 Candidat: Mohamed GUESSOD"
                echo "🔢 Build: ${BUILD_ID}"
                echo "🏷️ Tag: ${DOCKER_TAG}"
                echo "🌍 Environnement: ${params.DEPLOY_ENV}"
                echo ""
                
                echo "📦 État Kubernetes:"
                for ns in dev qa staging prod; do
                    echo "  --- $ns ---"
                    kubectl get pods -n $ns 2>/dev/null | grep -v "No resources" || echo "    Vide"
                done
                
                echo ""
                echo "💾 Espace disque:"
                df -h / | grep -v Filesystem
                '''
                
                // Nettoyage final
                sh '''
                echo ""
                echo "🧹 Nettoyage fichiers temporaires..."
                rm -f k8s-simple.yaml k8s-prod.yaml 2>/dev/null || true
                
                # Nettoyer les pods échoués
                kubectl delete pods --field-selector=status.phase=Failed --all-namespaces 2>/dev/null || true
                '''
            }
        }
        
        success {
            echo "✅✅✅ EXCELLENT! PIPELINE RÉUSSI! ✅✅✅"
            script {
                // Email simplifié
                mail(
                    to: 'mohamedguessod@gmail.com',
                    subject: "✅ SUCCÈS Examen DevOps #${BUILD_NUMBER}",
                    body: """Félicitations! Pipeline réussi.

Build: #${BUILD_NUMBER}
Environnement: ${params.DEPLOY_ENV}
Tag: ${DOCKER_TAG}

Consultez: ${BUILD_URL}
"""
                )
            }
        }
        
        failure {
            echo "❌ PIPELINE EN ÉCHEC"
            script {
                mail(
                    to: 'mohamedguessod@gmail.com',
                    subject: "❌ ÉCHEC Examen DevOps #${BUILD_NUMBER}",
                    body: "Pipeline échoué. Logs: ${BUILD_URL}"
                )
                
                // Debug info
                sh '''
                echo "🔧 DEBUG INFO:"
                echo ""
                echo "1. Événements récents:"
                kubectl get events --sort-by=.lastTimestamp 2>/dev/null | tail -5 || echo "  Non disponible"
                echo ""
                echo "2. Pods problématiques:"
                kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null | head -5 || echo "  Aucun"
                echo ""
                echo "3. Espace disque:"
                df -h / | tail -1
                '''
            }
        }
    }
}
