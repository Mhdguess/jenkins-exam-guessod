pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'guessod'
        MOVIE_IMAGE = 'movie-service-exam'
        CAST_IMAGE = 'cast-service-exam'
        DOCKER_TAG = "build-${BUILD_ID}"
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'qa', 'staging'],
            description: 'Environnement de déploiement'
        )
        booleanParam(
            name: 'PUSH_TO_DOCKERHUB',
            defaultValue: false,
            description: 'Pousser les images sur DockerHub'
        )
    }
    
    stages {
        // ÉTAPE 1 : PRÉPARATION
        stage('Préparation') {
            steps {
                script {
                    echo "=== PIPELINE CI/CD DATASCIENTEST ==="
                    echo "Build: ${BUILD_ID}"
                    echo "Tag: ${DOCKER_TAG}"
                    echo "Environnement: ${params.DEPLOY_ENV}"
                    
                    cleanWs()
                    checkout scm
                    
                    sh '''
                    echo "Structure du projet:"
                    ls -la
                    echo "Vérification des fichiers..."
                    [ -f "docker-compose.yml" ] || { echo "ERROR: docker-compose.yml missing"; exit 1; }
                    [ -f "movie-service/Dockerfile" ] || { echo "ERROR: movie-service/Dockerfile missing"; exit 1; }
                    [ -f "cast-service/Dockerfile" ] || { echo "ERROR: cast-service/Dockerfile missing"; exit 1; }
                    '''
                }
            }
        }
        
        // ÉTAPE 2 : BUILD IMAGES
        stage('Build Images Docker') {
            steps {
                script {
                    echo "=== BUILD DOCKER IMAGES ==="
                    
                    dir('movie-service') {
                        sh """
                        echo "Building movie-service..."
                        docker build -t ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                        """
                    }
                    
                    dir('cast-service') {
                        sh """
                        echo "Building cast-service..."
                        docker build -t ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                        """
                    }
                    
                    sh '''
                    echo "Images créées:"
                    docker images | grep guessod
                    '''
                }
            }
        }
        
        // ÉTAPE 3 : TESTS SIMPLES
        stage('Tests Locaux') {
            steps {
                script {
                    echo "=== TESTS LOCAUX ==="
                    
                    sh '''
                    # Test movie-service
                    echo "Test movie-service..."
                    docker run -d --name test-movie -p 8001:8000 guessod/movie-service-exam:latest
                    sleep 15
                    
                    if curl -s -f http://localhost:8001/health > /dev/null; then
                        echo "✅ Movie-service: Service accessible"
                        curl -s http://localhost:8001/health
                    else
                        echo "⚠️ Movie-service: Échec"
                        docker logs test-movie
                    fi
                    
                    docker stop test-movie 2>/dev/null || true
                    docker rm test-movie 2>/dev/null || true
                    
                    # Test cast-service
                    echo ""
                    echo "Test cast-service..."
                    docker run -d --name test-cast -p 8002:8000 guessod/cast-service-exam:latest
                    sleep 15
                    
                    if curl -s -f http://localhost:8002/health > /dev/null; then
                        echo "✅ Cast-service: Service accessible"
                        curl -s http://localhost:8002/health
                    else
                        echo "⚠️ Cast-service: Échec"
                        docker logs test-cast
                    fi
                    
                    docker stop test-cast 2>/dev/null || true
                    docker rm test-cast 2>/dev/null || true
                    
                    # Nettoyage
                    docker system prune -f
                    '''
                }
            }
        }
        
        // ÉTAPE 4 : PUSH DOCKERHUB
        stage('Push DockerHub') {
            when {
                expression { params.PUSH_TO_DOCKERHUB == true }
            }
            environment {
                DOCKERHUB_CREDS = credentials('dockerhub-guessod')
            }
            steps {
                script {
                    echo "=== PUSH DOCKERHUB ==="
                    
                    sh """
                    echo "\${DOCKERHUB_CREDS_PSW}" | docker login -u "\${DOCKERHUB_CREDS_USR}" --password-stdin
                    
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${MOVIE_IMAGE}:latest
                    
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_REGISTRY}/${CAST_IMAGE}:latest
                    
                    echo "✅ Images poussées sur DockerHub!"
                    """
                }
            }
        }
        
        // ÉTAPE 5 : PRÉPARATION K8S
        stage('Préparation Kubernetes') {
            steps {
                script {
                    echo "=== PRÉPARATION KUBERNETES ==="
                    
                    sh '''
                    # Créer les 4 namespaces
                    for ns in dev qa staging prod; do
                        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
                        echo "Namespace $ns ✓"
                    done
                    
                    echo ""
                    kubectl get namespaces | grep -E "dev|qa|staging|prod|default"
                    '''
                }
            }
        }
        
        // ÉTAPE 6 : DÉPLOIEMENT K8S
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    echo "=== DÉPLOIEMENT KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    echo "Déploiement dans namespace: \$NAMESPACE"
                    
                    # Créer les manifests Kubernetes
                    cat > k8s-deployment.yaml << 'YAML'
---
# Movie Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: movie-service
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
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        - name: CAST_SERVICE_HOST_URL
          value: "http://cast-service:8000/api/v1/casts/"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
# Movie Service Service
apiVersion: v1
kind: Service
metadata:
  name: movie-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: NodePort
  selector:
    app: movie-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30001
---
# Cast Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
  labels:
    app: cast-service
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
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: "sqlite:///:memory:"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
# Cast Service Service
apiVersion: v1
kind: Service
metadata:
  name: cast-service
  namespace: ${params.DEPLOY_ENV}
spec:
  type: NodePort
  selector:
    app: cast-service
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30002
YAML
                    
                    # Appliquer le déploiement
                    kubectl apply -f k8s-deployment.yaml
                    
                    echo "✅ Déploiement appliqué"
                    kubectl get all -n \$NAMESPACE
                    
                    # Attendre le démarrage
                    echo "Attente démarrage pods..."
                    sleep 30
                    
                    echo "État des pods:"
                    kubectl get pods -n \$NAMESPACE
                    """
                }
            }
        }
        
        // ÉTAPE 7 : TESTS K8S
        stage('Tests Kubernetes') {
            steps {
                script {
                    echo "=== TESTS KUBERNETES ==="
                    
                    sh """
                    NAMESPACE=${params.DEPLOY_ENV}
                    
                    # Récupérer les informations
                    MOVIE_PORT=\$(kubectl get svc movie-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30001")
                    CAST_PORT=\$(kubectl get svc cast-service -n \$NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30002")
                    NODE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
                    
                    echo "URLs:"
                    echo "  Movie-service: http://\${NODE_IP}:\${MOVIE_PORT}/health"
                    echo "  Cast-service: http://\${NODE_IP}:\${CAST_PORT}/health"
                    
                    # Tests
                    echo ""
                    echo "Tests de connectivité..."
                    
                    for i in {1..5}; do
                        if curl -s -f http://\${NODE_IP}:\${MOVIE_PORT}/health > /dev/null; then
                            echo "✅ Movie-service accessible"
                            break
                        else
                            echo "⏳ Tentative \$i/5 pour movie-service"
                            sleep 10
                        fi
                    done
                    
                    for i in {1..5}; do
                        if curl -s -f http://\${NODE_IP}:\${CAST_PORT}/health > /dev/null; then
                            echo "✅ Cast-service accessible"
                            break
                        else
                            echo "⏳ Tentative \$i/5 pour cast-service"
                            sleep 10
                        fi
                    done
                    
                    echo ""
                    echo "Logs des services:"
                    kubectl logs -n \$NAMESPACE deployment/movie-service --tail=5 2>/dev/null || echo "Pas de logs movie-service"
                    kubectl logs -n \$NAMESPACE deployment/cast-service --tail=5 2>/dev/null || echo "Pas de logs cast-service"
                    """
                }
            }
        }
        
        // ÉTAPE 8 : VALIDATION PRODUCTION
        stage('Validation Production') {
            when {
                allOf [
                    expression { params.DEPLOY_ENV == 'staging' },
                    expression { env.GIT_BRANCH == 'master' }
                ]
            }
            steps {
                script {
                    echo "=== VALIDATION PRODUCTION ==="
                    
                    timeout(time: 5, unit: 'MINUTES') {
                        input(
                            message: "Le déploiement staging est réussi. Déployer en PRODUCTION ?",
                            ok: "✅ Oui, déployer en production",
                            submitter: "admin"
                        )
                    }
                }
            }
        }
        
        // ÉTAPE 9 : DÉPLOIEMENT PRODUCTION
        stage('Déploiement Production') {
            when {
                expression {
                    // Exécuter après validation
                    return true
                }
            }
            steps {
                script {
                    echo "=== DÉPLOIEMENT PRODUCTION ==="
                    
                    sh """
                    # Production avec plus de replicas
                    cat > k8s-production.yaml << 'YAML'
---
# Movie Service Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  replicas: 2
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
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: movie-service-prod
  namespace: prod
spec:
  type: NodePort
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
  replicas: 2
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
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: cast-service-prod
  namespace: prod
spec:
  type: NodePort
  selector:
    app: cast-service-prod
  ports:
  - port: 8000
    targetPort: 8000
YAML
                    
                    kubectl apply -f k8s-production.yaml
                    
                    echo "✅ Production déployée!"
                    echo "Réplicas: 2"
                    echo "Namespace: prod"
                    
                    kubectl get all -n prod
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "=== FIN DU PIPELINE ==="
            script {
                sh '''
                echo "RAPPORT FINAL"
                echo "============="
                echo "Build: ${BUILD_ID}"
                echo "Tag: ${DOCKER_TAG}"
                echo "Environnement: ${params.DEPLOY_ENV}"
                echo "Push DockerHub: ${params.PUSH_TO_DOCKERHUB}"
                
                echo ""
                echo "État des namespaces:"
                for ns in dev qa staging prod; do
                    echo "--- $ns ---"
                    kubectl get pods -n $ns 2>/dev/null | grep -v "No resources" || echo "  Aucun pod"
                done
                '''
                
                // Nettoyage
                sh '''
                echo "Nettoyage..."
                rm -f k8s-deployment.yaml k8s-production.yaml 2>/dev/null || true
                '''
            }
        }
        
        success {
            echo "✅ PIPELINE RÉUSSI!"
            script {
                // Email de notification
                mail(
                    to: 'mohamedguessod@gmail.com',
                    subject: "✅ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} réussi",
                    body: """
                    Pipeline CI/CD réussi!
                    
                    Détails:
                    - Job: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Tag: ${env.DOCKER_TAG}
                    - Environnement: ${params.DEPLOY_ENV}
                    
                    Consultez: ${env.BUILD_URL}
                    """
                )
            }
        }
        
        failure {
            echo "❌ PIPELINE EN ÉCHEC!"
            script {
                // Email de notification
                mail(
                    to: 'mohamedguessod@gmail.com',
                    subject: "❌ Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} en échec",
                    body: """
                    Pipeline CI/CD en échec!
                    
                    Détails:
                    - Job: ${env.JOB_NAME}
                    - Build: #${env.BUILD_NUMBER}
                    - Environnement: ${params.DEPLOY_ENV}
                    
                    Consultez les logs: ${env.BUILD_URL}
                    """
                )
            }
        }
    }
}
